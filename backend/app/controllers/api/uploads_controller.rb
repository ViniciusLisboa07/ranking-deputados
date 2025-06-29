require 'csv'

class Api::UploadsController < ApplicationController
  before_action :validate_file, only: [:create]

  def create
    begin
      temp_file = save_temp_file
      puts "Arquivo salvo em: #{temp_file.path}"
      
      csv_validation = validate_csv_content(temp_file.path)
      puts "Validação do CSV: #{csv_validation}"
      unless csv_validation[:valid]
        temp_file.unlink
        render json: {
          message: 'Arquivo CSV inválido',
          error: csv_validation[:error]
        }, status: :unprocessable_entity
        return
      end
      
      upload_id = SecureRandom.hex(16)
      
      permanent_file_path = Rails.root.join('tmp', 'uploads', "#{upload_id}.csv")
      FileUtils.mkdir_p(File.dirname(permanent_file_path))
      FileUtils.cp(temp_file.path, permanent_file_path)
      
      puts "Arquivo salvo em: #{permanent_file_path}"

      temp_file.unlink
      
      Rails.cache.write("upload_#{upload_id}_status", {
        status: 'queued',
        message: 'Arquivo adicionado à fila de processamento',
        queued_at: Time.current
      })
      
      puts "Enviando para processamento em background"
      CsvProcessorJob.perform_later(permanent_file_path.to_s, upload_id)
      
      render json: {
        message: 'Arquivo enviado para processamento em background',
        upload_id: upload_id,
        status_url: "/api/uploads/#{upload_id}/status"
      }, status: :accepted
      
    rescue => e
      temp_file&.unlink
      
      render json: {
        message: 'Erro interno no servidor',
        error: e.message
      }, status: :internal_server_error
    end
  end

  def show_status
    upload_id = params[:id]
    status = Rails.cache.read("upload_#{upload_id}_status")
    
    if status
      render json: {
        upload_id: upload_id,
        **status
      }
    else
      render json: {
        message: 'Upload não encontrado',
        error: 'ID de upload inválido ou expirado'
      }, status: :not_found
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
