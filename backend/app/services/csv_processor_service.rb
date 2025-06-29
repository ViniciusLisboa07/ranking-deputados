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
    
    CSV.foreach(@file_path, headers: true, col_sep: ';', quote_char: '"', encoding: 'UTF-8') do |row|
      begin
        process_row(row)
        @processed_count += 1
        
        if @processed_count % 1000 == 0
          puts "Processados #{@processed_count} registros..."
        end
      rescue => e
        @error_count += 1
        @errors << { row: @processed_count + 1, error: e.message }
        puts "Erro na linha #{@processed_count + 1}: #{e.message}"
      end
    end

    puts "Processamento concluído!"
    puts "Total processado: #{@processed_count}"
    puts "Total de erros: #{@error_count}"
    
    {
      success: true,
      processed_count: @processed_count,
      error_count: @error_count,
      errors: @errors
    }
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

  def process_row(row)
    deputado = get_or_create_deputado(row)
    
    create_despesa(row, deputado) if deputado
  end

  def get_or_create_deputado(row)
    nome = row['txNomeParlamentar']
    deputado_id = row['nuDeputadoId']
    
    return nil if nome.blank? || deputado_id.blank?

    cache_key = "#{nome}_#{deputado_id}"
    
    unless @deputados_cache[cache_key]
      @deputados_cache[cache_key] = Deputado.find_or_create_by(
        nome: nome,
        deputado_id: deputado_id.to_i
      ) do |dep|
        dep.cpf = row['cpf']
        dep.carteira_parlamentar = row['nuCarteiraParlamentar']
        dep.uf = row['sgUF']
        dep.partido = row['sgPartido']
      end
    end

    @deputados_cache[cache_key]
  end

  def create_despesa(row, deputado)
    data_emissao = nil
    if row['datEmissao'].present?
      begin
        data_emissao = Date.parse(row['datEmissao'])
      rescue Date::Error
        data_emissao = nil
      end
    end

    valor_documento = parse_decimal(row['vlrDocumento'])
    valor_glosa = parse_decimal(row['vlrGlosa'])
    valor_liquido = parse_decimal(row['vlrLiquido'])

    Despesa.create!(
      deputado: deputado,
      descricao: row['txtDescricao'],
      especificacao: row['txtDescricaoEspecificacao'],
      fornecedor: row['txtFornecedor'],
      cnpj_cpf_fornecedor: row['txtCNPJCPF'],
      numero_documento: row['txtNumero'],
      tipo_documento: row['indTipoDocumento']&.to_i,
      data_emissao: data_emissao,
      valor_documento: valor_documento,
      valor_glosa: valor_glosa,
      valor_liquido: valor_liquido,
      mes: row['numMes']&.to_i,
      ano: row['numAno']&.to_i,
      parcela: row['numParcela']&.to_i,
      passageiro: row['txtPassageiro'],
      trecho: row['txtTrecho'],
      lote: row['numLote'],
      url_documento: row['urlDocumento']
    )
  end

  def parse_decimal(value)
    return nil if value.blank?
    
    cleaned_value = value.to_s.gsub(/["']/, '')
    BigDecimal(cleaned_value) rescue nil
  end
end
