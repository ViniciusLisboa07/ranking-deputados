class DeputadoService

  def query_deputados(params)
    @deputados = Deputado.all
    @deputados = @deputados.where(uf: params[:uf]) if params[:uf].present?
    @deputados = @deputados.where(partido: params[:partido]) if params[:partido].present?
    
    if params[:search].present?
      @deputados = @deputados.where("nome ILIKE ?", "%#{params[:search]}%")
    end

    case params[:order_by]
    when 'nome'
      @deputados = @deputados.order(:nome)
    when 'partido'
      @deputados = @deputados.order(:partido, :nome)
    when 'uf'
      @deputados = @deputados.order(:uf, :nome)
    else
      @deputados = @deputados.order(:nome)
    end

    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min
    offset = (page - 1) * per_page

    total_count = @deputados.count

    deputados_with_stats = @deputados
      .left_joins(:despesas)
      .select(
        'deputados.*',
        'COALESCE(SUM(despesas.valor_liquido), 0) as total_despesas',
        'COUNT(despesas.id) as total_documentos'
      )
      .group('deputados.id')
      .limit(per_page)
      .offset(offset)
      .map do |deputado|
        {
          id: deputado.id,
          nome: deputado.nome,
          cpf: deputado.cpf,
          carteira_parlamentar: deputado.carteira_parlamentar,
          uf: deputado.uf,
          partido: deputado.partido,
          deputado_id: deputado.deputado_id,
          total_despesas: BigDecimal(deputado.total_despesas.to_s),
          total_documentos: deputado.total_documentos.to_i,
          created_at: deputado.created_at,
          updated_at: deputado.updated_at
        }
      end

    {
      deputados: deputados_with_stats,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  def find_deputado(id)
    deputado = Deputado.find_by(deputado_id: id)
    return nil unless deputado

    despesas = deputado.despesas

    total_gastos = despesas.sum(:valor_liquido).to_f

    despesas_array = despesas
      .select(:id, :data_emissao, :fornecedor, :valor_liquido, :url_documento, :descricao)
      .order(valor_liquido: :desc, data_emissao: :desc)
      .to_a

    maior_despesa = despesas_array.first

    todas_despesas = despesas_array.map do |despesa|
      {
        id: despesa.id,
        data_emissao: despesa.data_emissao,
        fornecedor: despesa.fornecedor,
        valor_liquido: despesa.valor_liquido.to_f,
        url_documento: despesa.url_documento,
        descricao: despesa.descricao,
        is_maior_despesa: (maior_despesa && despesa.id == maior_despesa.id)
      }
    end

    {
      id: deputado.id,
      nome: deputado.nome,
      cpf: deputado.cpf,
      carteira_parlamentar: deputado.carteira_parlamentar,
      uf: deputado.uf,
      partido: deputado.partido,
      deputado_id: deputado.deputado_id,
      created_at: deputado.created_at,
      updated_at: deputado.updated_at,
      total_gastos: total_gastos,
      total_despesas: despesas_array.count,
      maior_despesa: maior_despesa ? {
        id: maior_despesa.id,
        data_emissao: maior_despesa.data_emissao,
        fornecedor: maior_despesa.fornecedor,
        valor_liquido: maior_despesa.valor_liquido.to_f,
        url_documento: maior_despesa.url_documento,
        descricao: maior_despesa.descricao
      } : nil,
      despesas: todas_despesas
    }
  end
end