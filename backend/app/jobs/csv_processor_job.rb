class CsvProcessorJob < ApplicationJob
  queue_as :default

  def perform(file_path, upload_id)
    Rails.cache.write("upload_#{upload_id}_status", {
      status: 'processing',
      message: 'Processando arquivo CSV...',
      started_at: Time.current
    })

    begin
      processor = CsvProcessorService.new(file_path)
      result = processor.process
      
      Rails.cache.write("upload_#{upload_id}_status", {
        status: result[:success] ? 'completed' : 'failed',
        message: result[:success] ? 'Arquivo processado com sucesso!' : 'Erro ao processar arquivo',
        result: result,
        completed_at: Time.current
      })

      puts "Processamento concluído para upload #{upload_id}"
    rescue => e
      puts "Erro no processamento do upload #{upload_id}: #{e.message}"
      
      Rails.cache.write("upload_#{upload_id}_status", {
        status: 'failed',
        message: 'Erro interno no processamento',
        error: e.message,
        completed_at: Time.current
      })
    ensure
      # Limpar arquivo temporário
      File.delete(file_path) if File.exist?(file_path)
    end
  end
end 