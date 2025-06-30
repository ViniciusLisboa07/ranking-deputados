require 'test_helper'

class DeputadoServiceTest < ActiveSupport::TestCase
  def setup
    @service = DeputadoService.new
  end
  
  test "should return all deputados with pagination" do
    result = @service.query_deputados({})
    
    assert result.key?(:deputados)
    assert result.key?(:pagination)
    
    deputados = result[:deputados]
    pagination = result[:pagination]
    
    assert deputados.is_a?(Array)
    assert_equal 1, pagination[:current_page]
    assert_equal 20, pagination[:per_page]
    assert pagination[:total_count] >= 0
    assert pagination[:total_pages] >= 0
  end

  test "should filter deputados by UF" do
    result = @service.query_deputados({ uf: 'SP' })
    
    deputados = result[:deputados]
    sp_deputados = deputados.select { |d| d[:uf] == 'SP' }
    
    assert_equal deputados.count, sp_deputados.count
  end

  test "should filter deputados by partido" do
    result = @service.query_deputados({ partido: 'PT' })
    
    deputados = result[:deputados]
    pt_deputados = deputados.select { |d| d[:partido] == 'PT' }
    
    assert_equal deputados.count, pt_deputados.count
  end

  test "should filter deputados by search term" do
    result = @service.query_deputados({ search: 'João' })
    
    deputados = result[:deputados]
    joao_deputados = deputados.select { |d| d[:nome].downcase.include?('joão') }
    
    assert_equal deputados.count, joao_deputados.count
  end

  test "should combine multiple filters" do
    result = @service.query_deputados({ 
      uf: 'SP', 
      partido: 'PT', 
      search: 'Silva' 
    })
    
    deputados = result[:deputados]
    filtered_deputados = deputados.select do |d| 
      d[:uf] == 'SP' && 
      d[:partido] == 'PT' && 
      d[:nome].downcase.include?('silva')
    end
    
    assert_equal deputados.count, filtered_deputados.count
  end

  test "should order deputados by nome" do
    result = @service.query_deputados({ order_by: 'nome' })
    
    deputados = result[:deputados]
    nomes = deputados.map { |d| d[:nome] }
    nomes_ordenados = nomes.sort
    
    assert_equal nomes_ordenados, nomes
  end

  test "should order deputados by partido" do
    result = @service.query_deputados({ order_by: 'partido' })
    
    deputados = result[:deputados]
    # Verificar se está ordenado por partido e depois por nome
    assert deputados.each_cons(2).all? { |a, b| 
      a[:partido] < b[:partido] || 
      (a[:partido] == b[:partido] && a[:nome] <= b[:nome]) 
    }
  end

  test "should order deputados by uf" do
    result = @service.query_deputados({ order_by: 'uf' })
    
    deputados = result[:deputados]
    # Verificar se está ordenado por UF e depois por nome
    assert deputados.each_cons(2).all? { |a, b| 
      a[:uf] < b[:uf] || 
      (a[:uf] == b[:uf] && a[:nome] <= b[:nome]) 
    }
  end

  test "should default to nome ordering for invalid order_by" do
    result = @service.query_deputados({ order_by: 'invalid' })
    
    deputados = result[:deputados]
    nomes = deputados.map { |d| d[:nome] }
    nomes_ordenados = nomes.sort
    
    assert_equal nomes_ordenados, nomes
  end

  test "should handle custom pagination" do
    result = @service.query_deputados({ page: 1, per_page: 5 })
    
    deputados = result[:deputados]
    pagination = result[:pagination]
    
    assert deputados.count <= 5
    assert_equal 1, pagination[:current_page]
    assert_equal 5, pagination[:per_page]
  end

  test "should handle page parameter correctly" do
    result = @service.query_deputados({ page: 2, per_page: 2 })
    pagination = result[:pagination]
    
    assert_equal 2, pagination[:current_page]
    assert_equal 2, pagination[:per_page]
  end

  test "should handle negative page number" do
    result = @service.query_deputados({ page: -1 })
    pagination = result[:pagination]
    
    assert_equal 1, pagination[:current_page]
  end

  test "should limit per_page to maximum 100" do
    result = @service.query_deputados({ per_page: 150 })
    pagination = result[:pagination]
    
    assert_equal 100, pagination[:per_page]
  end

  test "should include total_despesas and total_documentos" do
    result = @service.query_deputados({})
    
    deputados = result[:deputados]
    
    deputados.each do |deputado|
      assert deputado.key?(:total_despesas)
      assert deputado.key?(:total_documentos)
      assert deputado[:total_despesas].is_a?(BigDecimal)
      assert deputado[:total_documentos].is_a?(Integer)
    end
  end

  test "should return correct deputado structure" do
    result = @service.query_deputados({})
    
    deputados = result[:deputados]
    
    if deputados.any?
      deputado = deputados.first
      expected_keys = [
        :id, :nome, :cpf, :carteira_parlamentar, :uf, :partido, 
        :deputado_id, :total_despesas, :total_documentos, 
        :created_at, :updated_at
      ]
      
      expected_keys.each do |key|
        assert deputado.key?(key), "Missing key: #{key}"
      end
    end
  end

  # ==========================================
  # FIND_DEPUTADO Tests
  # ==========================================

  test "should find deputado by deputado_id" do
    deputado_record = deputados(:joao_silva)
    result = @service.find_deputado(deputado_record.deputado_id)
    
    assert result
    assert_equal deputado_record.id, result[:id]
    assert_equal deputado_record.nome, result[:nome]
    assert_equal deputado_record.cpf, result[:cpf]
    assert_equal deputado_record.uf, result[:uf]
    assert_equal deputado_record.partido, result[:partido]
  end

  test "should return nil for non-existent deputado" do
    result = @service.find_deputado(999999)
    
    assert_nil result
  end

  test "should include deputado details" do
    deputado_record = deputados(:joao_silva)
    result = @service.find_deputado(deputado_record.deputado_id)
    
    expected_keys = [
      :id, :nome, :cpf, :carteira_parlamentar, :uf, :partido, 
      :deputado_id, :created_at, :updated_at, :total_gastos, 
      :total_despesas, :maior_despesa, :despesas
    ]
    
    expected_keys.each do |key|
      assert result.key?(key), "Missing key: #{key}"
    end
  end

  test "should calculate total_gastos correctly" do
    deputado_record = deputados(:joao_silva)
    result = @service.find_deputado(deputado_record.deputado_id)
    
    expected_total = deputado_record.despesas.sum(:valor_liquido).to_f
    
    assert_equal expected_total, result[:total_gastos]
  end

  test "should count total_despesas correctly" do
    deputado_record = deputados(:joao_silva)
    result = @service.find_deputado(deputado_record.deputado_id)
    
    expected_count = deputado_record.despesas.count
    
    assert_equal expected_count, result[:total_despesas]
  end

  test "should identify maior_despesa" do
    deputado_record = deputados(:joao_silva)
    result = @service.find_deputado(deputado_record.deputado_id)
    
    if result[:despesas].any?
      maior_despesa = result[:maior_despesa]
      despesas_com_flag = result[:despesas].select { |d| d[:is_maior_despesa] }
      
      assert maior_despesa
      assert_equal 1, despesas_com_flag.count
      assert_equal maior_despesa[:id], despesas_com_flag.first[:id]
    end
  end

  test "should order despesas by valor_liquido desc" do
    deputado_record = deputados(:joao_silva)
    result = @service.find_deputado(deputado_record.deputado_id)
    
    despesas = result[:despesas]
    
    if despesas.count > 1
      valores = despesas.map { |d| d[:valor_liquido] }
      valores_ordenados = valores.sort.reverse
      
      assert_equal valores_ordenados, valores
    end
  end

  test "should include despesa structure" do
    deputado_record = deputados(:joao_silva)
    result = @service.find_deputado(deputado_record.deputado_id)
    
    despesas = result[:despesas]
    
    if despesas.any?
      despesa = despesas.first
      expected_keys = [
        :id, :data_emissao, :fornecedor, :valor_liquido, 
        :url_documento, :descricao, :is_maior_despesa
      ]
      
      expected_keys.each do |key|
        assert despesa.key?(key), "Missing key: #{key}"
      end
    end
  end

  test "should handle deputado without despesas" do
    deputado_sem_despesas = Deputado.create!(
      nome: 'Deputado Sem Gastos',
      cpf: '00000000000',
      carteira_parlamentar: '999',
      uf: 'DF',
      partido: 'TEST',
      deputado_id: 999999
    )
    
    result = @service.find_deputado(deputado_sem_despesas.deputado_id)
    
    assert result
    assert_equal 0.0, result[:total_gastos]
    assert_equal 0, result[:total_despesas]
    assert_nil result[:maior_despesa]
    assert_equal [], result[:despesas]
    
    deputado_sem_despesas.destroy
  end

  # ==========================================
  # GET_STATISTICS Tests
  # ==========================================

  test "should return complete statistics structure" do
    result = @service.get_statistics
    
    assert result.key?(:resumo)
    assert result.key?(:distribuicoes)
    assert result.key?(:rankings)
  end

  test "should include resumo statistics" do
    result = @service.get_statistics
    resumo = result[:resumo]
    
    expected_keys = [:total_deputados, :total_despesas, :valor_medio_por_deputado]
    expected_keys.each do |key|
      assert resumo.key?(key), "Missing key in resumo: #{key}"
    end
    
    assert resumo[:total_deputados].is_a?(Integer)
    assert resumo[:total_despesas].is_a?(Float)
    assert resumo[:valor_medio_por_deputado].is_a?(Float)
  end

  test "should calculate valor_medio_por_deputado correctly" do
    result = @service.get_statistics
    resumo = result[:resumo]
    
    if resumo[:total_deputados] > 0
      expected_media = (resumo[:total_despesas] / resumo[:total_deputados]).round(2)
      assert_equal expected_media, resumo[:valor_medio_por_deputado]
    else
      assert_equal 0, resumo[:valor_medio_por_deputado]
    end
  end

  test "should handle zero deputados gracefully" do
    # Usar transação para garantir rollback automático
    ActiveRecord::Base.transaction do
      # Deletar na ordem correta: despesas primeiro, depois deputados
      Despesa.delete_all
      Deputado.delete_all
      
      result = @service.get_statistics
      resumo = result[:resumo]
      
      assert_equal 0, resumo[:total_deputados]
      assert_equal 0.0, resumo[:total_despesas]
      assert_equal 0, resumo[:valor_medio_por_deputado]
      
      # Forçar rollback para restaurar dados
      raise ActiveRecord::Rollback
    end
  end

  test "should include distribuicoes statistics" do
    result = @service.get_statistics
    distribuicoes = result[:distribuicoes]
    
    expected_keys = [
      :deputados_por_uf, :deputados_por_partido, 
      :gastos_por_uf, :gastos_por_partido
    ]
    
    expected_keys.each do |key|
      assert distribuicoes.key?(key), "Missing key in distribuicoes: #{key}"
    end
  end

  test "should include rankings statistics" do
    result = @service.get_statistics
    rankings = result[:rankings]
    
    expected_keys = [:top_gastadores, :top_categorias]
    expected_keys.each do |key|
      assert rankings.key?(key), "Missing key in rankings: #{key}"
    end
  end

  test "should limit top_gastadores to default 10" do
    result = @service.get_statistics
    top_gastadores = result[:rankings][:top_gastadores]
    
    assert top_gastadores.count <= 10
  end

  test "should respect custom limit for top_gastadores" do
    result = @service.get_statistics({ limit: 5 })
    top_gastadores = result[:rankings][:top_gastadores]
    
    assert top_gastadores.count <= 5
  end

  test "should include correct structure for top_gastadores" do
    result = @service.get_statistics
    top_gastadores = result[:rankings][:top_gastadores]
    
    if top_gastadores.any?
      gastador = top_gastadores.first
      expected_keys = [:id, :nome, :uf, :partido, :total_gasto]
      
      expected_keys.each do |key|
        assert gastador.key?(key), "Missing key in top_gastadores: #{key}"
      end
      
      assert gastador[:total_gasto].is_a?(Float)
    end
  end

  test "should order top_gastadores by total_gasto desc" do
    result = @service.get_statistics
    top_gastadores = result[:rankings][:top_gastadores]
    
    if top_gastadores.count > 1
      gastos = top_gastadores.map { |g| g[:total_gasto] }
      gastos_ordenados = gastos.sort.reverse
      
      assert_equal gastos_ordenados, gastos
    end
  end

  test "should include top_categorias" do
    result = @service.get_statistics
    top_categorias = result[:rankings][:top_categorias]
    
    assert top_categorias.is_a?(Hash)
    
    if top_categorias.any?
      top_categorias.each do |categoria, valor|
        assert categoria.is_a?(String)
        assert valor.is_a?(Float)
      end
    end
  end

  test "should convert all monetary values to float" do
    result = @service.get_statistics
    
    # Verificar resumo
    assert result[:resumo][:total_despesas].is_a?(Float)
    assert result[:resumo][:valor_medio_por_deputado].is_a?(Float)
    
    # Verificar distribuições
    result[:distribuicoes][:gastos_por_uf].each_value do |valor|
      assert valor.is_a?(Float)
    end
    
    result[:distribuicoes][:gastos_por_partido].each_value do |valor|
      assert valor.is_a?(Float)
    end
    
    # Verificar rankings
    result[:rankings][:top_gastadores].each do |gastador|
      assert gastador[:total_gasto].is_a?(Float)
    end
    
    result[:rankings][:top_categorias].each_value do |valor|
      assert valor.is_a?(Float)
    end
  end

  # ==========================================
  # INTEGRATION Tests
  # ==========================================

  test "should handle complex query with all parameters" do
    result = @service.query_deputados({
      uf: 'SP',
      partido: 'PT',
      search: 'Silva',
      order_by: 'nome',
      page: 1,
      per_page: 10
    })
    
    assert result[:deputados].is_a?(Array)
    assert result[:pagination][:current_page] == 1
    assert result[:pagination][:per_page] == 10
  end

  test "should maintain consistency between service methods" do
    query_result = @service.query_deputados({ per_page: 1 })
    
    if query_result[:deputados].any?
      deputado_from_query = query_result[:deputados].first
      deputado_details = @service.find_deputado(deputado_from_query[:deputado_id])
      
      if deputado_details
        assert_equal deputado_from_query[:id], deputado_details[:id]
        assert_equal deputado_from_query[:nome], deputado_details[:nome]
        assert_equal deputado_from_query[:uf], deputado_details[:uf]
        assert_equal deputado_from_query[:partido], deputado_details[:partido]
      end
    end
  end

  test "should handle empty database gracefully" do
    # Usar transação para garantir rollback automático
    ActiveRecord::Base.transaction do
      # Deletar na ordem correta: despesas primeiro, depois deputados
      Despesa.delete_all
      Deputado.delete_all
      
      # Testar query_deputados
      query_result = @service.query_deputados({})
      assert_equal [], query_result[:deputados]
      assert_equal 0, query_result[:pagination][:total_count]
      
      # Testar find_deputado
      find_result = @service.find_deputado(1)
      assert_nil find_result
      
      # Testar get_statistics
      stats_result = @service.get_statistics
      assert_equal 0, stats_result[:resumo][:total_deputados]
      assert_equal 0.0, stats_result[:resumo][:total_despesas]
      
      # Forçar rollback para restaurar dados
      raise ActiveRecord::Rollback
    end
  end

  # ==========================================
  # EDGE CASES & ERROR HANDLING
  # ==========================================

  test "should handle nil parameters gracefully" do
    # O service agora trata parâmetros nil corretamente
    result = @service.query_deputados(nil)
    
    assert result.key?(:deputados)
    assert result.key?(:pagination)
    
    # Deve usar valores padrão quando params é nil
    assert_equal 1, result[:pagination][:current_page]
    assert_equal 20, result[:pagination][:per_page]
  end

  test "should handle empty string filters" do
    result = @service.query_deputados({ 
      uf: '', 
      partido: '', 
      search: '' 
    })
    
    assert result[:deputados].is_a?(Array)
  end

  test "should handle zero and negative per_page" do
    result1 = @service.query_deputados({ per_page: 0 })
    result2 = @service.query_deputados({ per_page: -5 })
    
    # O service agora garante que per_page seja sempre pelo menos 1
    assert_equal 1, result1[:pagination][:per_page]
    assert_equal 1, result2[:pagination][:per_page]
  end

  test "should handle string parameters for numeric fields" do
    result = @service.query_deputados({ 
      page: 'abc', 
      per_page: 'xyz' 
    })
    
    # Strings inválidas se tornam 0 com to_i, mas o service garante valores mínimos
    assert result[:pagination][:current_page] == 1  # page: 'abc'.to_i = 0, mas mínimo é 1
    assert result[:pagination][:per_page] == 1      # per_page: 'xyz'.to_i = 0, mas mínimo é 1
  end

  test "should handle very large page numbers" do
    result = @service.query_deputados({ page: 999999 })
    
    # Deve retornar página válida mesmo se não houver dados
    assert result[:pagination][:current_page] == 999999
    assert result[:deputados].is_a?(Array)
  end
end 