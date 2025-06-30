require "test_helper"

class Api::RankingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @joao_silva = deputados(:joao_silva)
    @maria_santos = deputados(:maria_santos)
    @pedro_oliveira = deputados(:pedro_oliveira)
    @ana_costa = deputados(:ana_costa)
  end

  test "should get rankings index successfully" do
    get api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('data')
    assert json_response.key?('meta')
    assert json_response['meta'].key?('ranking_type')
    assert json_response['meta'].key?('generated_at')
  end

  test "should default to gastos_totais ranking" do
    get api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['meta']['ranking_type'] == 'gastos_totais'
  end

  test "should get gastos totais ranking successfully" do
    get gastos_totais_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert ranking.is_a?(Array)
    ranking.each_with_index do |item, index|
      assert item.key?('posicao')
      assert item.key?('deputado')
      assert item.key?('total_gasto')
      assert item.key?('documentos_count')
      
      assert_equal index + 1, item['posicao']
      assert item['deputado'].key?('id')
      assert item['deputado'].key?('nome')
      assert item['deputado'].key?('uf')
      assert item['deputado'].key?('partido')
      assert item['total_gasto'].is_a?(Numeric)
      assert item['documentos_count'].is_a?(Integer)
    end
  end

  test "should order gastos totais by value desc" do
    get gastos_totais_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    if ranking.size > 1
      gastos = ranking.map { |item| item['total_gasto'] }
      assert_equal gastos.sort.reverse, gastos
    end
  end

  test "should limit gastos totais ranking" do
    get gastos_totais_api_rankings_url, params: { limit: 3 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    assert ranking.size <= 3
  end

  test "should get por categoria ranking successfully" do
    get por_categoria_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert ranking.is_a?(Array)
    assert json_response.key?('meta')
    assert json_response['meta'].key?('categoria')
    
    ranking.each do |item|
      assert item.key?('posicao')
      assert item.key?('deputado')
      assert item.key?('total_gasto')
      assert item.key?('categoria')
      assert item['total_gasto'].is_a?(Numeric)
    end
  end

  test "should filter por categoria específica" do
    get por_categoria_api_rankings_url, params: { categoria: 'PASSAGEM' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['meta']['categoria'].include?('PASSAGEM')
  end

  test "should get ranking geral por estados" do
    get por_estado_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert ranking.is_a?(Array)
    ranking.each do |item|
      assert item.key?('posicao')
      assert item.key?('uf')
      assert item.key?('total_gasto')
      assert item.key?('deputados_count')
      assert item.key?('gasto_medio_por_deputado')
      assert item['total_gasto'].is_a?(Numeric)
      assert item['deputados_count'].is_a?(Integer)
      assert item['gasto_medio_por_deputado'].is_a?(Numeric)
    end
  end

  test "should get ranking por estado específico" do
    get por_estado_api_rankings_url, params: { uf: 'SP' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert json_response.key?('meta')
    assert json_response['meta']['uf'] == 'SP'
    
    ranking.each do |item|
      assert item['deputado']['uf'] == 'SP'
    end
  end

  test "should get ranking geral por partidos" do
    get por_partido_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert ranking.is_a?(Array)
    ranking.each do |item|
      assert item.key?('posicao')
      assert item.key?('partido')
      assert item.key?('total_gasto')
      assert item.key?('deputados_count')
      assert item.key?('gasto_medio_por_deputado')
      assert item['total_gasto'].is_a?(Numeric)
      assert item['deputados_count'].is_a?(Integer)
      assert item['gasto_medio_por_deputado'].is_a?(Numeric)
    end
  end

  test "should get ranking por partido específico" do
    get por_partido_api_rankings_url, params: { partido: 'PT' }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert json_response.key?('meta')
    assert json_response['meta']['partido'] == 'PT'
    
    ranking.each do |item|
      assert item['deputado']['partido'] == 'PT'
    end
  end

  test "should get eficiencia gastos ranking successfully" do
    get eficiencia_gastos_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert ranking.is_a?(Array)
    assert json_response.key?('meta')
    assert json_response['meta'].key?('tipo')
    assert json_response['meta'].key?('min_documentos')
    
    ranking.each do |item|
      assert item.key?('posicao')
      assert item.key?('deputado')
      assert item.key?('total_gasto')
      assert item.key?('documentos_count')
      assert item.key?('gasto_por_documento')
      assert item['gasto_por_documento'].is_a?(Numeric)
      assert item['documentos_count'] >= (json_response['meta']['min_documentos'] || 10)
    end
  end

  test "should order eficiencia by lowest spending" do
    get eficiencia_gastos_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    if ranking.size > 1
      gastos = ranking.map { |item| item['total_gasto'] }
      assert_equal gastos.sort, gastos
    end
  end

  test "should respect min_documentos parameter" do
    get eficiencia_gastos_api_rankings_url, params: { min_documentos: 3 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert json_response['meta']['min_documentos'] == 3
    ranking.each do |item|
      assert item['documentos_count'] >= 3
    end
  end

  test "should get comparativo temporal successfully" do
    get comparativo_temporal_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    assert ranking.is_a?(Array)
    assert json_response.key?('meta')
    assert json_response['meta'].key?('ano_atual')
    assert json_response['meta'].key?('ano_anterior')
    
    ranking.each do |item|
      assert item.key?('deputado')
      assert item.key?('gasto_atual')
      assert item.key?('gasto_anterior')
      assert item.key?('diferenca_absoluta')
      assert item.key?('variacao_percentual')
      
      assert item['gasto_atual'].is_a?(Numeric)
      assert item['gasto_anterior'].is_a?(Numeric)
      assert item['diferenca_absoluta'].is_a?(Numeric)
    end
  end

  test "should use custom years in comparativo temporal" do
    get comparativo_temporal_api_rankings_url, params: { 
      ano_atual: 2024, 
      ano_anterior: 2023 
    }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['meta']['ano_atual'] == 2024
    assert json_response['meta']['ano_anterior'] == 2023
  end

  test "should order comparativo by biggest difference" do
    get comparativo_temporal_api_rankings_url
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    if ranking.size > 1
      diferencas = ranking.map { |item| item['diferenca_absoluta'] }
      assert_equal diferencas.sort.reverse, diferencas
    end
  end

  test "should apply filters correctly" do
    get gastos_totais_api_rankings_url, params: { 
      uf: 'SP',
      ano: 2024,
      mes: 3
    }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    
    ranking.each do |item|
      assert item['deputado']['uf'] == 'SP'
    end
  end

  test "should handle year and month filters" do
    get gastos_totais_api_rankings_url, params: { 
      ano: 2024,
      mes: 3
    }
    assert_response :success
  end

  test "should handle invalid parameters gracefully" do
    get gastos_totais_api_rankings_url, params: { 
      limit: 'invalid',
      ano: 'invalid',
      mes: 'invalid'
    }
    assert_response :success
  end

  test "should handle empty results gracefully" do
    get gastos_totais_api_rankings_url, params: { 
      uf: 'INEXISTENTE'
    }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['data'].is_a?(Array)
  end

  test "should limit results correctly" do
    get gastos_totais_api_rankings_url, params: { limit: 1 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    ranking = json_response['data']
    assert ranking.size <= 1
  end

  test "should handle zero limit" do
    get gastos_totais_api_rankings_url, params: { limit: 0 }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['data'].is_a?(Array)
  end

  test "rankings should respond quickly" do
    start_time = Time.current
    
    get gastos_totais_api_rankings_url
    assert_response :success
    
    response_time = Time.current - start_time
    assert response_time < 5.0, "Response took too long: #{response_time}s"
  end

  test "all ranking endpoints should be accessible" do
    endpoints = %w[
      gastos_totais por_categoria por_estado 
      por_partido eficiencia_gastos comparativo_temporal
    ]
    
    endpoints.each do |endpoint|
      get "/api/rankings/#{endpoint}"
      assert_response :success, "Failed to access #{endpoint} endpoint"
    end
  end
end
