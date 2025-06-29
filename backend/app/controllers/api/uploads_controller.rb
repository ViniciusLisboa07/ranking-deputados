class Api::UploadsController < ApplicationController
  before_action :validate_file, only: [:create]

  def create
    begin
      temp_file = save_temp_file
      
      csv_validation = validate_csv_content(temp_file.path)
      unless csv_validation[:valid]
        temp_file.unlink
        render json: {
          message: 'Arquivo CSV inválido',
          error: csv_validation[:error]
        }, status: :unprocessable_entity
        return
      end
      
      processor = CsvProcessorService.new(temp_file.path)
      result = processor.process
      
      temp_file.unlink
      
      if result[:success]
        render json: {
          message: 'Arquivo processado com sucesso!',
          data: {
            processed_count: result[:processed_count],
            error_count: result[:error_count],
            errors: result[:errors]
          }
        }, status: :ok
      else
        render json: {
          message: 'Erro ao processar arquivo',
          error: result[:error]
        }, status: :unprocessable_entity
      end
      
    rescue => e
      temp_file&.unlink
      
      render json: {
        message: 'Erro interno no servidor',
        error: e.message
      }, status: :internal_server_error
    end
  end

  def status
    deputados_count = Deputado.count
    despesas_count = Despesa.count
    
    render json: {
      message: 'Status do banco de dados',
      data: {
        deputados_count: deputados_count,
        despesas_count: despesas_count,
        last_updated: Despesa.maximum(:updated_at)
      }
    }
  end

  private

  def validate_file
    unless params[:file].present?
      render json: { 
        message: 'Nenhum arquivo foi enviado',
        error: 'Parâmetro file é obrigatório'
      }, status: :bad_request
      return
    end

    file = params[:file]
    
    unless file.content_type.in?(['text/csv', 'application/csv', 'text/plain'])
      render json: { 
        message: 'Tipo de arquivo inválido',
        error: 'Apenas arquivos CSV são permitidos'
      }, status: :bad_request
      return
    end

    if file.size > 80.megabytes
      render json: { 
        message: 'Arquivo muito grande',
        error: 'Tamanho máximo permitido: 80MB'
      }, status: :bad_request
      return
    end

    unless file.original_filename&.downcase&.end_with?('.csv')
      render json: { 
        message: 'Extensão de arquivo inválida',
        error: 'O arquivo deve ter extensão .csv'
      }, status: :bad_request
      return
    end
  end

  def validate_csv_content(file_path)
    # Usar apenas a configuração que funciona
    csv_config = { col_sep: ';', quote_char: '"', encoding: 'UTF-8', liberal_parsing: true }

    begin
      CSV.foreach(file_path, headers: true, **csv_config).with_index do |row, index|
        break if index >= 1
      end
      
      return { valid: true }
      
    rescue => e
      return {
        valid: false,
        error: "Arquivo CSV não pode ser lido. O arquivo deve estar formatado com:\n" +
               " Separador: ponto e vírgula (;)\n" +
               " Codificação: UTF-8\n" +
               " Primeira linha deve conter os cabeçalhos das colunas\n" +
               "\nErro técnico: #{e.message}"
      }
    end
  end

  def save_temp_file
    file = params[:file]
    
    temp_file = Tempfile.new(['upload', '.csv'])
    temp_file.binmode
    temp_file.write(file.read)
    temp_file.rewind
    temp_file.close
    
    temp_file
  end
end
