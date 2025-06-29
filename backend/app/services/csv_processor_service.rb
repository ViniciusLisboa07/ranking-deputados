require 'csv'

class CsvProcessorService
  def initialize(file_path)
    @file_path = file_path
    @deputados_cache = {}
    @processed_count = 0
    @error_count = 0
    @errors = []
    @batch_size = 10000
    @current_batch = []
    @total_inserted = 0
  end

  def process
    puts "Iniciando processamento do arquivo CSV: #{@file_path}"

    csv_config = { col_sep: ';', quote_char: '"', encoding: 'UTF-8', liberal_parsing: true }

    begin
      test_count = 0
      CSV.foreach(@file_path, headers: true, **csv_config) do |row|
        test_count += 1
        break if test_count >= 5
      end
      
      puts "Configuração validada! Processando arquivo completo..."
    rescue => e
      puts "Erro ao validar configuração CSV: #{e.message}"
      return {
        success: false,
        error: "Arquivo CSV não pode ser processado. Certifique-se de que está formatado corretamente (separador ';', encoding UTF-8).",
        processed_count: 0,
        error_count: 0
      }
    end

    process_with_batches(csv_config)
    
  rescue => e
    puts "Erro geral no processamento: #{e.message}"
    {
      success: false,
      error: e.message,
      processed_count: @processed_count,
      error_count: @error_count
    }
  end

  private

  def process_with_batches(config)
    puts "Processando com configuração: #{config}"
    puts "Batch size: #{@batch_size} registros"
    
    initial_despesas_count = Despesa.count
    initial_deputados_count = Deputado.count
    puts "Estado inicial: #{initial_deputados_count} deputados, #{initial_despesas_count} despesas"
    
    CSV.foreach(@file_path, headers: true, **config) do |row|
      begin
        process_row_to_batch(row)
        @processed_count += 1
        
        if @current_batch.size >= @batch_size
          process_current_batch
        end
        
        if @processed_count % 10000 == 0
          puts "Processados #{@processed_count} registros... Batches inseridos: #{@total_inserted}"
        end
        
      rescue => e
        @error_count += 1
        error_message = "Linha #{@processed_count + 1}: #{e.message}"
        @errors << error_message
        puts "ERRO na #{error_message}"
        puts "Backtrace: #{e.backtrace.first(3).join(', ')}"
        
        if @error_count > 100 && @processed_count < 10
          raise "Muitos erros no início do arquivo. Verifique o formato."
        end
      end
    end
    
    if @current_batch.any?
      puts "Processando último batch de #{@current_batch.size} registros..."
      process_current_batch
    end

    final_despesas_count = Despesa.count
    final_deputados_count = Deputado.count
    despesas_created = final_despesas_count - initial_despesas_count
    deputados_created = final_deputados_count - initial_deputados_count
    
    puts "Processamento concluído!"
    puts "Total processado: #{@processed_count}"
    puts "Total de erros: #{@error_count}"
    puts "Deputados criados: #{deputados_created}"
    puts "Despesas criadas: #{despesas_created}"
    puts "Total de registros inseridos via batch: #{@total_inserted}"
    
    {
      success: true,
      processed_count: @processed_count,
      error_count: @error_count,
      errors: @errors.first(20),
      deputados_created: deputados_created,
      despesas_created: despesas_created
    }
  end

  def process_row_to_batch(row)
    puts "Processando linha #{@processed_count + 1}..." if @processed_count % 5000 == 0
    
    deputado = get_or_create_deputado(row)
    unless deputado
      puts "AVISO: Deputado não pôde ser criado/encontrado para linha #{@processed_count + 1}" if @processed_count % 10000 == 0
      @error_count += 1
      return
    end
    
    # Criar dados da despesa para o batch
    despesa_data = build_despesa_data(row, deputado)
    if despesa_data
      @current_batch << despesa_data
      puts "Adicionado ao batch (#{@current_batch.size}/#{@batch_size})" if @current_batch.size % 200 == 0
    else
      puts "AVISO: Dados da despesa não puderam ser construídos para linha #{@processed_count + 1}"
      @error_count += 1
    end
  end

  def process_current_batch
    return if @current_batch.empty?
    
    begin
      invalid_records = @current_batch.select { |record| record[:deputado_id].nil? }
      if invalid_records.any?
        puts "ERRO: #{invalid_records.size} registros com deputado_id nulo encontrados!"
        @current_batch.reject! { |record| record[:deputado_id].nil? }
        @error_count += invalid_records.size
      end
      
      if @current_batch.empty?
        puts "AVISO: Batch vazio após filtrar registros inválidos"
        return
      end
      
      puts "Inserindo batch de #{@current_batch.size} despesas..."
      
      Despesa.transaction do
        result = Despesa.insert_all(@current_batch)
        puts "Resultado do insert_all: #{result.inspect}"
        @total_inserted += @current_batch.size
      end
      
    rescue => e
      puts "ERRO ao inserir batch: #{e.message}"
      puts "Classe do erro: #{e.class}"
      puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
      
      puts "Tentando inserção individual para identificar problemas..."
      @current_batch.each_with_index do |despesa_data, index|
        begin
          despesa = Despesa.create!(despesa_data.except(:created_at, :updated_at))
          @total_inserted += 1
          puts "✅ Registro individual #{index + 1} inserido (ID: #{despesa.id})" if index % 100 == 0
        rescue => individual_error
          @error_count += 1
          error_msg = "Erro no registro #{index + 1} do batch: #{individual_error.message}"
          @errors << error_msg
          puts "❌ #{error_msg}"
          puts "Dados problemáticos: #{despesa_data.inspect}" if index < 3 # Mostrar só os primeiros
        end
      end
    ensure
      @current_batch.clear
      puts "=== FIM DO BATCH ==="
    end
  end

  def get_or_create_deputado(row)
    nome = clean_field(row['txNomeParlamentar'])
    deputado_id = clean_field(row['nuDeputadoId'])
    
    if deputado_id.blank?
      puts "AVISO: deputado_id em branco - pulando registro"
      return nil
    end

    cache_key = "#{nome}_#{deputado_id.to_i}"
    
    unless @deputados_cache[cache_key]
      begin
        puts "Criando/buscando deputado: #{nome || 'SEM NOME'} (ID: #{deputado_id})" if @deputados_cache.size % 50 == 0
        
        @deputados_cache[cache_key] = Deputado.find_or_create_by(
          deputado_id: deputado_id.to_i
        ) do |dep|
          dep.nome = nome  # Pode ser nil/vazio
          dep.cpf = clean_field(row['cpf'])
          dep.carteira_parlamentar = clean_field(row['nuCarteiraParlamentar'])
          dep.uf = clean_field(row['sgUF'])
          dep.partido = clean_field(row['sgPartido'])
        end
        
        puts "Deputado #{nome || 'SEM NOME'} criado/encontrado (ID do banco: #{@deputados_cache[cache_key].id})"
      rescue => e
        puts "ERRO ao criar deputado #{nome || 'SEM NOME'}: #{e.message}"
        puts "Backtrace: #{e.backtrace.first(2).join(', ')}"
        return nil
      end
    end

    @deputados_cache[cache_key]
  end

  def build_despesa_data(row, deputado)
    if deputado.nil? || deputado.id.nil?
      puts "ERRO: Deputado nulo ou sem ID ao construir despesa"
      return nil
    end
    
    data_emissao = nil
    if row['datEmissao'].present?
      begin
        data_emissao = Date.parse(clean_field(row['datEmissao']))
      rescue Date::Error => e
        puts "AVISO: Data inválida '#{row['datEmissao']}': #{e.message}" if @processed_count % 10000 == 0
        data_emissao = nil
      end
    end

    valor_documento = parse_decimal(row['vlrDocumento'])
    valor_glosa = parse_decimal(row['vlrGlosa'])
    valor_liquido = parse_decimal(row['vlrLiquido'])

    data = {
      deputado_id: deputado.id,
      descricao: clean_field(row['txtDescricao']),
      especificacao: clean_field(row['txtDescricaoEspecificacao']),
      fornecedor: clean_field(row['txtFornecedor']),
      cnpj_cpf_fornecedor: clean_field(row['txtCNPJCPF']),
      numero_documento: clean_field(row['txtNumero']),
      tipo_documento: clean_field(row['indTipoDocumento'])&.to_i,
      data_emissao: data_emissao,
      valor_documento: valor_documento,
      valor_glosa: valor_glosa,
      valor_liquido: valor_liquido,
      mes: clean_field(row['numMes'])&.to_i,
      ano: clean_field(row['numAno'])&.to_i,
      parcela: clean_field(row['numParcela'])&.to_i,
      passageiro: clean_field(row['txtPassageiro']),
      trecho: clean_field(row['txtTrecho']),
      lote: clean_field(row['numLote']),
      url_documento: clean_field(row['urlDocumento']),
      created_at: Time.current,
      updated_at: Time.current
    }
    
    if data[:deputado_id].nil?
      puts "ERRO: deputado_id nulo nos dados da despesa"
      return nil
    end
    
    if data[:descricao].blank? && data[:fornecedor].blank? && data[:valor_liquido].nil?
      puts "AVISO: Registro com dados muito limitados - linha #{@processed_count + 1}"
    end
    
    data
  end

  def clean_field(value)
    return nil if value.blank?
    
    cleaned = value.to_s.strip
    
    if cleaned.start_with?('"') && cleaned.end_with?('"')
      cleaned = cleaned[1..-2]
    end
    
    if cleaned.start_with?("'") && cleaned.end_with?("'")
      cleaned = cleaned[1..-2]
    end
    
    cleaned.blank? ? nil : cleaned
  end

  def parse_decimal(value)
    return nil if value.blank?
    
    cleaned_value = clean_field(value)
    return nil if cleaned_value.blank?
    
    cleaned_value = cleaned_value.gsub(/[^\d.,-]/, '')
    cleaned_value = cleaned_value.gsub(',', '.')
    
    BigDecimal(cleaned_value) rescue nil
  end
end

