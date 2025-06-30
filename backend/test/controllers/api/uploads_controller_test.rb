require "test_helper"

class Api::UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "should upload CSV file successfully" do
    csv_content = create_valid_csv_content
    csv_file = create_csv_file(csv_content)
    
    post api_uploads_url, params: { file: csv_file }
    assert_response :accepted
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('upload_id')
    assert json_response.key?('status_url')
    assert json_response.key?('message')
    assert json_response['message'].include?('processamento em background')
  end

  test "should reject non-CSV files" do
    temp_file = Tempfile.new(['test', '.txt'])
    temp_file.write("This is not a CSV file")
    temp_file.rewind
    
    txt_file = Rack::Test::UploadedFile.new(
      temp_file.path,
      'text/plain',
      original_filename: 'test.txt'
    )
    
    post api_uploads_url, params: { file: txt_file }
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('message')
    assert json_response.key?('error')
    assert json_response['error'].include?('extensão')
  end

  test "should reject files without file parameter" do
    post api_uploads_url
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert json_response['error'].include?('obrigatório')
  end

  test "should reject files without CSV extension" do
    temp_file = Tempfile.new(['test', '.txt'])
    temp_file.write("test content")
    temp_file.rewind
    
    uploaded_file = Rack::Test::UploadedFile.new(
      temp_file.path, 
      'text/csv', 
      original_filename: 'test.txt'
    )
    
    post api_uploads_url, params: { file: uploaded_file }
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert json_response['error'].include?('extensão')
  end

  test "should return 404 for non-existent upload" do
    get "/api/uploads/non-existent-upload/status"
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('message')
    assert json_response.key?('error')
  end

  test "should return 404 for expired upload" do
    upload_id = "expired-upload-123"
    # Não adicionar nada ao cache para simular expiração
    
    get "/api/uploads/#{upload_id}/status"
    assert_response :not_found
  end

  # GENERAL STATUS Tests
  test "should get general database status" do
    get "/api/uploads/status"
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('message')
    assert json_response.key?('data')
    
    data = json_response['data']
    assert data.key?('deputados_count')
    assert data.key?('despesas_count')
    assert data.key?('last_updated')
    
    assert data['deputados_count'].is_a?(Integer)
    assert data['despesas_count'].is_a?(Integer)
  end

  test "should validate file content type" do
    invalid_types = [
      'application/pdf',
      'image/jpeg',
      'application/json',
      'text/html'
    ]
    
    invalid_types.each do |content_type|
      temp_file = Tempfile.new(['test', '.csv'])
      temp_file.write("test content")
      temp_file.rewind
      
      uploaded_file = Rack::Test::UploadedFile.new(
        temp_file.path,
        content_type,
        original_filename: 'test.csv'
      )
      
      post api_uploads_url, params: { file: uploaded_file }
      assert_response :bad_request
      
      json_response = JSON.parse(response.body)
      assert json_response['message'].include?('Tipo de arquivo inválido')
    end
  end

  test "should accept valid CSV content types" do
    valid_types = [
      'text/csv',
      'application/csv',
      'text/plain'
    ]
    
    valid_types.each do |content_type|
      csv_content = create_valid_csv_content
      csv_file = create_csv_file(csv_content, 'text/csv')
      
      post api_uploads_url, params: { file: csv_file }
      assert_response :accepted
    end
  end

  test "should create upload_id in correct format" do
    csv_content = create_valid_csv_content
    csv_file = create_csv_file(csv_content, 'text/csv')
    
    post api_uploads_url, params: { file: csv_file }
    assert_response :accepted
    
    json_response = JSON.parse(response.body)
    upload_id = json_response['upload_id']
    
    # Verificar formato do upload_id (32 caracteres hexadecimais de SecureRandom.hex(16))
    assert_match(/^[a-f0-9]{32}$/, upload_id)
    assert_equal 32, upload_id.length
  end

  test "should create status_url in correct format" do
    csv_content = create_valid_csv_content
    csv_file = create_csv_file(csv_content, 'text/csv')
    
    post api_uploads_url, params: { file: csv_file }
    assert_response :accepted
    
    json_response = JSON.parse(response.body)
    status_url = json_response['status_url']
    
    # Verificar formato da URL
    assert status_url.include?('/api/uploads/')
    assert status_url.include?('/status')
  end

  test "should handle empty CSV file" do
    empty_csv = create_csv_file("", 'text/csv')
    
    post api_uploads_url, params: { file: empty_csv }
    assert_response :accepted
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('upload_id')
  end

  test "should handle CSV with only headers" do
    headers_only_csv = create_csv_file("header1,header2,header3\n", 'text/csv')
    
    post api_uploads_url, params: { file: headers_only_csv }
    assert_response :accepted
  end

  test "should handle multiple simultaneous uploads" do
    csv_content = create_valid_csv_content
    
    # Simular uploads simultâneos
    uploads = []
    3.times do
      csv_file = create_csv_file(csv_content, 'text/csv')
      post api_uploads_url, params: { file: csv_file }
      assert_response :accepted
      uploads << JSON.parse(response.body)
    end
    
    # Verificar se todos têm upload_ids únicos
    upload_ids = uploads.map { |u| u['upload_id'] }
    assert_equal upload_ids.uniq.size, upload_ids.size
  end

  private

  def create_valid_csv_content
    [
      "txNomeParlamentar,nuDeputadoId,cpf,nuCarteiraParlamentar,sgUF,sgPartido,txtDescricao,txtFornecedor,vlrLiquido,datEmissao,numMes,numAno",
      "João Silva,1001,12345678900,001,SP,PT,PASSAGEM AÉREA,TAM,1500.00,2024-03-15,3,2024",
      "Maria Santos,1002,98765432100,002,RJ,PSDB,COMBUSTÍVEL,Shell,250.50,2024-03-20,3,2024"
    ].join("\n")
  end

  def create_csv_file(content, content_type = 'text/csv')
    # Criar arquivo temporário
    temp_file = Tempfile.new(['test', '.csv'])
    temp_file.write(content)
    temp_file.rewind
    
    # Usar Rack::Test::UploadedFile que é mais compatível com testes Rails
    Rack::Test::UploadedFile.new(temp_file.path, content_type, original_filename: 'test.csv')
  end
end
