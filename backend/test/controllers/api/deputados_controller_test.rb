require "test_helper"

class Api::DeputadosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @joao_silva = deputados(:joao_silva)
    @maria_santos = deputados(:maria_santos)
    @pedro_oliveira = deputados(:pedro_oliveira)
    @ana_costa = deputados(:ana_costa)
  end

  test "should get deputados index successfully" do
    get api_deputados_url
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

  test "should filter deputados by uf" do
    get api_deputados_url, params: { uf: 'SP' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    sp_deputados = json_response['data']
    assert sp_deputados.all? { |dep| dep['uf'] == 'SP' }
    assert sp_deputados.any? { |dep| dep['nome'] == 'João Silva' }
  end

  test "should filter deputados by partido" do
    get api_deputados_url, params: { partido: 'PT' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    pt_deputados = json_response['data']
    assert pt_deputados.all? { |dep| dep['partido'] == 'PT' }
    assert pt_deputados.size >= 2 # João Silva e Ana Costa
  end

  test "should search deputados by name" do
    get api_deputados_url, params: { search: 'João' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    found_deputados = json_response['data']
    assert found_deputados.any? { |dep| dep['nome'].include?('João') }
  end

  test "should order deputados by nome" do
    get api_deputados_url, params: { order_by: 'nome' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    names = json_response['data'].map { |dep| dep['nome'] }
    assert_equal names.sort, names
  end

  test "should handle pagination correctly" do
    get api_deputados_url, params: { page: 1, per_page: 2 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['data'].size
    assert_equal 1, json_response['meta']['current_page']
    assert_equal 2, json_response['meta']['per_page']
  end

  test "should include despesas statistics in deputados" do
    get api_deputados_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    first_deputado = json_response['data'].first
    
    assert first_deputado.key?('total_despesas'), "Missing total_despesas field"
    assert first_deputado.key?('total_documentos'), "Missing total_documentos field"
    assert first_deputado['total_documentos'].is_a?(Integer), "total_documentos should be integer"
  end

  # SHOW Tests
  test "should get deputado details successfully" do
    get api_deputado_url(@joao_silva.deputado_id)
    assert_response :success
    
    json_response = JSON.parse(response.body)
    deputado_data = json_response['data']
    
    assert_equal @joao_silva.nome, deputado_data['nome']
    assert_equal @joao_silva.uf, deputado_data['uf']
    assert_equal @joao_silva.partido, deputado_data['partido']
    assert deputado_data.key?('total_gastos')
    assert deputado_data.key?('total_despesas')
    assert deputado_data.key?('maior_despesa')
    assert deputado_data.key?('despesas')
    assert deputado_data['despesas'].is_a?(Array)
  end

  test "should highlight maior despesa correctly" do
    get api_deputado_url(@joao_silva.deputado_id)
    assert_response :success
    
    json_response = JSON.parse(response.body)
    deputado_data = json_response['data']
    
    # Verificar se há maior_despesa
    assert deputado_data['maior_despesa']
    maior_despesa = deputado_data['maior_despesa']
    
    # Verificar se a maior despesa está marcada na lista
    despesa_marcada = deputado_data['despesas'].find { |d| d['is_maior_despesa'] }
    assert despesa_marcada
    assert_equal maior_despesa['id'], despesa_marcada['id']
  end

  test "should return despesas ordered by valor desc" do
    get api_deputado_url(@joao_silva.deputado_id)
    assert_response :success
    
    json_response = JSON.parse(response.body)
    despesas = json_response['data']['despesas']
    
    valores = despesas.map { |d| d['valor_liquido'] }
    assert_equal valores.sort.reverse, valores
  end

  test "should return 404 for non-existent deputado" do
    get api_deputado_url(99999)
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('message')
    assert json_response.key?('error')
  end

  # STATISTICS Tests
  test "should get statistics successfully" do
    get statistics_api_deputados_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    stats = json_response['data']
    
    assert stats.key?('resumo')
    assert stats.key?('distribuicoes')
    assert stats.key?('rankings')
    
    # Verificar resumo
    resumo = stats['resumo']
    assert resumo.key?('total_deputados')
    assert resumo.key?('total_despesas')
    assert resumo.key?('valor_medio_por_deputado')
    
    # Verificar distribuições
    distribuicoes = stats['distribuicoes']
    assert distribuicoes.key?('deputados_por_uf')
    assert distribuicoes.key?('deputados_por_partido')
    assert distribuicoes.key?('gastos_por_uf')
    assert distribuicoes.key?('gastos_por_partido')
    
    # Verificar rankings
    rankings = stats['rankings']
    assert rankings.key?('top_gastadores')
    assert rankings.key?('top_categorias')
    assert rankings['top_gastadores'].is_a?(Array)
    assert rankings['top_categorias'].is_a?(Hash)
  end

  test "should limit top gastadores correctly" do
    get statistics_api_deputados_url, params: { limit: 2 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    top_gastadores = json_response['data']['rankings']['top_gastadores']
    assert top_gastadores.size <= 2
  end

  test "should calculate correct statistics values" do
    get statistics_api_deputados_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    resumo = json_response['data']['resumo']
    
    assert resumo['total_deputados'] >= 4
    assert resumo['total_despesas'] > 0
    assert resumo['valor_medio_por_deputado'] > 0
  end

  test "should order gastos por uf correctly" do
    get statistics_api_deputados_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    gastos_por_uf = json_response['data']['distribuicoes']['gastos_por_uf']
    
    valores = gastos_por_uf.values
    assert_equal valores.sort.reverse, valores
  end

  test "should have top gastadores with required fields" do
    get statistics_api_deputados_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    top_gastadores = json_response['data']['rankings']['top_gastadores']
    
    if top_gastadores.any?
      primeiro = top_gastadores.first
      assert primeiro.key?('id')
      assert primeiro.key?('nome')
      assert primeiro.key?('uf')
      assert primeiro.key?('partido')
      assert primeiro.key?('total_gasto')
      assert primeiro['total_gasto'].is_a?(Numeric)
    end
  end

  # Edge Cases
  test "should handle empty search gracefully" do
    get api_deputados_url, params: { search: '' }
    assert_response :success
  end

  test "should handle invalid page numbers" do
    get api_deputados_url, params: { page: -1 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['meta']['current_page']
  end

  test "should limit per_page to maximum" do
    get api_deputados_url, params: { per_page: 1000 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['meta']['per_page'] <= 100
  end
end
