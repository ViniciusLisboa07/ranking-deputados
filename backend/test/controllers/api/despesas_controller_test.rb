require "test_helper"

class Api::DespesasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @joao_silva = deputados(:joao_silva)
    @maria_santos = deputados(:maria_santos)
    @passagem_aerea = despesas(:passagem_aerea_joao)
    @combustivel = despesas(:combustivel_maria)
    @grande_despesa = despesas(:grande_despesa_joao)
  end

  test "should get despesas index successfully" do
    get api_despesas_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('data')
    assert json_response.key?('meta')
    assert json_response['data'].is_a?(Array)
    assert json_response['meta'].key?('current_page')
    assert json_response['meta'].key?('per_page')
    assert json_response['meta'].key?('total_count')
    assert json_response['meta'].key?('total_pages')
  end

  test "should include deputado information in despesas" do
    get api_despesas_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    first_despesa = json_response['data'].first
    
    assert first_despesa.key?('deputado')
    deputado_info = first_despesa['deputado']
    assert deputado_info.key?('id')
    assert deputado_info.key?('nome')
    assert deputado_info.key?('uf')
    assert deputado_info.key?('partido')
  end

  test "should filter despesas by deputado_id" do
    get api_despesas_url, params: { deputado_id: @joao_silva.id }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    assert despesas.all? { |d| d['deputado']['id'] == @joao_silva.id }
  end

  test "should filter despesas by uf" do
    get api_despesas_url, params: { uf: 'SP' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    assert despesas.all? { |d| d['deputado']['uf'] == 'SP' }
  end

  test "should filter despesas by partido" do
    get api_despesas_url, params: { partido: 'PT' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    assert despesas.all? { |d| d['deputado']['partido'] == 'PT' }
  end

  test "should filter despesas by mes and ano" do
    get api_despesas_url, params: { mes: 3, ano: 2024 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    assert despesas.all? { |d| d['mes'] == 3 && d['ano'] == 2024 }
  end

  test "should filter despesas by categoria" do
    get api_despesas_url, params: { categoria: 'PASSAGEM' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    assert despesas.all? { |d| d['descricao'].include?('PASSAGEM') }
  end

  test "should filter despesas by valor range" do
    get api_despesas_url, params: { valor_min: 200, valor_max: 2000 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    assert despesas.all? { |d| d['valor_liquido'] >= 200 && d['valor_liquido'] <= 2000 }
  end

  test "should filter despesas by fornecedor" do
    get api_despesas_url, params: { fornecedor: 'TAM' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    assert despesas.all? { |d| d['fornecedor'].include?('TAM') }
  end

  test "should order despesas by valor desc" do
    get api_despesas_url, params: { order_by: 'valor' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    valores = despesas.map { |d| d['valor_liquido'] }
    assert_equal valores.sort.reverse, valores
  end

  test "should order despesas by data desc" do
    get api_despesas_url, params: { order_by: 'data' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    # Verificar se está ordenado por data (mais recente primeiro)
    datas = despesas.map { |d| Date.parse(d['data_emissao']) }
    assert_equal datas.sort.reverse, datas
  end

  test "should handle pagination correctly" do
    get api_despesas_url, params: { page: 1, per_page: 2 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['data'].size <= 2
    assert_equal 1, json_response['meta']['current_page']
    assert_equal 2, json_response['meta']['per_page']
  end

  # SHOW Tests
  test "should get despesa details successfully" do
    get api_despesa_url(@passagem_aerea.id)
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesa_data = json_response['data']
    
    assert_equal @passagem_aerea.id, despesa_data['id']
    assert_equal @passagem_aerea.descricao, despesa_data['descricao']
    assert_equal @passagem_aerea.fornecedor, despesa_data['fornecedor']
    assert_equal @passagem_aerea.valor_liquido.to_f, despesa_data['valor_liquido']
    
    # Verificar informações do deputado
    assert despesa_data.key?('deputado')
    deputado_info = despesa_data['deputado']
    assert_equal @joao_silva.nome, deputado_info['nome']
    assert_equal @joao_silva.uf, deputado_info['uf']
    assert_equal @joao_silva.partido, deputado_info['partido']
    assert_equal @joao_silva.cpf, deputado_info['cpf']
    assert_equal @joao_silva.carteira_parlamentar, deputado_info['carteira_parlamentar']
  end

  test "should return 404 for non-existent despesa" do
    get api_despesa_url(99999)
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('message')
    assert json_response.key?('error')
  end

  # SUMMARY Tests
  test "should get despesas summary successfully" do
    get summary_api_despesas_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    summary_data = json_response['data']
    
    assert summary_data.key?('total_despesas')
    assert summary_data.key?('total_documentos')
    assert summary_data.key?('valor_medio')
    assert summary_data.key?('valor_mediano')
    assert summary_data.key?('despesas_por_categoria')
    assert summary_data.key?('despesas_por_mes')
    assert summary_data.key?('fornecedores_top')
    
    # Verificar tipos
    assert summary_data['total_despesas'].is_a?(Numeric)
    assert summary_data['total_documentos'].is_a?(Integer)
    assert summary_data['valor_medio'].is_a?(Numeric)
    assert summary_data['valor_mediano'].is_a?(Numeric)
    assert summary_data['despesas_por_categoria'].is_a?(Hash)
    assert summary_data['despesas_por_mes'].is_a?(Hash)
    assert summary_data['fornecedores_top'].is_a?(Hash)
  end

  test "should calculate summary values correctly" do
    get summary_api_despesas_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    summary_data = json_response['data']
    
    # Total despesas deve ser > 0
    assert summary_data['total_despesas'] > 0
    assert summary_data['total_documentos'] > 0
    assert summary_data['valor_medio'] > 0
    
    # Verificar se top categorias está ordenado
    categorias = summary_data['despesas_por_categoria']
    if categorias.any?
      valores = categorias.values
      assert_equal valores.sort.reverse, valores
    end
    
    # Verificar se top fornecedores está ordenado
    fornecedores = summary_data['fornecedores_top']
    if fornecedores.any?
      valores = fornecedores.values
      assert_equal valores.sort.reverse, valores
    end
  end

  test "should apply filters in summary" do
    # Testar summary com filtro por deputado
    get summary_api_despesas_url, params: { deputado_id: @joao_silva.id }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    summary_data = json_response['data']
    
    # Valores devem ser diferentes do summary completo
    assert summary_data['total_despesas'] > 0
    assert summary_data['total_documentos'] > 0
  end

  # Date Range Tests
  test "should filter by date range" do
    get api_despesas_url, params: { 
      data_inicio: '2024-01-01', 
      data_fim: '2024-03-31' 
    }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']
    
    despesas.each do |despesa|
      data_emissao = Date.parse(despesa['data_emissao'])
      assert data_emissao >= Date.parse('2024-01-01')
      assert data_emissao <= Date.parse('2024-03-31')
    end
  end

  test "should handle invalid date range gracefully" do
    get api_despesas_url, params: { 
      data_inicio: 'invalid-date', 
      data_fim: '2024-12-31' 
    }
    assert_response :success
    # Deve ignorar filtro de data inválido e retornar todas as despesas
  end

  # Edge Cases
  test "should handle empty filters gracefully" do
    get api_despesas_url, params: { 
      uf: '', 
      partido: '', 
      categoria: '',
      fornecedor: ''
    }
    assert_response :success
  end

  test "should handle invalid numeric filters" do
    get api_despesas_url, params: { 
      deputado_id: 'invalid',
      mes: 'invalid',
      ano: 'invalid',
      valor_min: 'invalid',
      valor_max: 'invalid'
    }
    assert_response :success
  end

  test "should limit per_page to maximum" do
    get api_despesas_url, params: { per_page: 1000 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['meta']['per_page'] <= 100
  end

  test "should handle zero valor filters" do
    get api_despesas_url, params: { valor_min: 0, valor_max: 0 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    # Pode não ter resultados, mas deve responder com sucesso
    assert json_response['data'].is_a?(Array)
  end

  test "should include all required fields in despesa response" do
    get api_despesas_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    first_despesa = json_response['data'].first
    
    required_fields = %w[
      id deputado descricao especificacao fornecedor
      numero_documento data_emissao valor_documento
      valor_glosa valor_liquido mes ano url_documento
    ]
    
    required_fields.each do |field|
      assert first_despesa.key?(field), "Missing field: #{field}"
    end
  end
end
