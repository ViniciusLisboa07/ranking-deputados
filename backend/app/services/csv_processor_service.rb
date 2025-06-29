require 'csv'

class CsvProcessorService
  def initialize(file_path)
    @file_path = file_path
    @deputados_cache = {}
    @processed_count = 0
    @error_count = 0
    @errors = []
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

    process_with_config(csv_config)
    
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

  def process_with_config(config)
    puts "Processando com configuração: #{config}"
    
    CSV.foreach(@file_path, headers: true, **config) do |row|
      begin
        process_row(row)
        @processed_count += 1
        
        if @processed_count % 1000 == 0
          puts "Processados #{@processed_count} registros..."
        end
      rescue => e
        @error_count += 1
        error_message = "Linha #{@processed_count + 1}: #{e.message}"
        @errors << error_message
        puts "Erro na #{error_message}"
        
        if @error_count > 100 && @processed_count < 10
          raise "Muitos erros no início do arquivo. Verifique o formato."
        end
      end
    end

    puts "Processamento concluído!"
    puts "Total processado: #{@processed_count}"
    puts "Total de erros: #{@error_count}"
    
    {
      success: true,
      processed_count: @processed_count,
      error_count: @error_count,
      errors: @errors.first(20)
    }
  end

  def process_row(row)
    deputado = get_or_create_deputado(row)
    
    create_despesa(row, deputado) if deputado
  end

  def get_or_create_deputado(row)
    nome = clean_field(row['txNomeParlamentar'])
    deputado_id = clean_field(row['nuDeputadoId'])
    
    return nil if nome.blank? || deputado_id.blank?

    cache_key = "#{nome}_#{deputado_id}"
    
    unless @deputados_cache[cache_key]
      @deputados_cache[cache_key] = Deputado.find_or_create_by(
        nome: nome,
        deputado_id: deputado_id.to_i
      ) do |dep|
        dep.cpf = clean_field(row['cpf'])
        dep.carteira_parlamentar = clean_field(row['nuCarteiraParlamentar'])
        dep.uf = clean_field(row['sgUF'])
        dep.partido = clean_field(row['sgPartido'])
      end
    end

    @deputados_cache[cache_key]
  end

  def create_despesa(row, deputado)
    data_emissao = nil
    if row['datEmissao'].present?
      begin
        data_emissao = Date.parse(clean_field(row['datEmissao']))
      rescue Date::Error
        data_emissao = nil
      end
    end

    valor_documento = parse_decimal(row['vlrDocumento'])
    valor_glosa = parse_decimal(row['vlrGlosa'])
    valor_liquido = parse_decimal(row['vlrLiquido'])

    Despesa.create!(
      deputado: deputado,
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
      url_documento: clean_field(row['urlDocumento'])
    )
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
