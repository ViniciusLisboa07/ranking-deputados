class Api::DeputadosController < ApplicationController
  before_action :set_deputado, only: [:show]

  def index
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
    per_page = [params[:per_page]&.to_i || 20, 100].min # Max 100 per page
    offset = (page - 1) * per_page

    total_count = @deputados.count
    @deputados = @deputados.limit(per_page).offset(offset)

    deputados_with_stats = @deputados.includes(:despesas).map do |deputado|
      {
        id: deputado.id,
        nome: deputado.nome,
        cpf: deputado.cpf,
        carteira_parlamentar: deputado.carteira_parlamentar,
        uf: deputado.uf,
        partido: deputado.partido,
        deputado_id: deputado.deputado_id,
        total_despesas: deputado.despesas.sum(:valor_liquido),
        total_documentos: deputado.despesas.count,
        created_at: deputado.created_at,
        updated_at: deputado.updated_at
      }
    end

    render json: {
      data: deputados_with_stats,
      meta: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  def show
    total_por_categoria = @deputado.despesas
      .group(:descricao)
      .sum(:valor_liquido)
      .transform_values { |v| v.to_f }

    total_por_mes = @deputado.despesas
      .group(:mes)
      .sum(:valor_liquido)
      .transform_values { |v| v.to_f }

    deputado_data = {
      id: @deputado.id,
      nome: @deputado.nome,
      cpf: @deputado.cpf,
      carteira_parlamentar: @deputado.carteira_parlamentar,
      uf: @deputado.uf,
      partido: @deputado.partido,
      deputado_id: @deputado.deputado_id,
      created_at: @deputado.created_at,
      updated_at: @deputado.updated_at,
      estatisticas: {
        total_despesas: @deputado.despesas.sum(:valor_liquido).to_f,
        total_documentos: @deputado.despesas.count,
        total_por_categoria: total_por_categoria,
        total_por_mes: total_por_mes,
        valor_medio_documento: @deputado.despesas.average(:valor_liquido)&.to_f || 0
      }
    }

    render json: { data: deputado_data }
  end

  def statistics
    stats = {
      total_deputados: Deputado.count,
      deputados_por_uf: Deputado.group(:uf).count,
      deputados_por_partido: Deputado.group(:partido).count,
      top_gastadores: Deputado.joins(:despesas)
        .group('deputados.id', 'deputados.nome', 'deputados.uf', 'deputados.partido')
        .sum('despesas.valor_liquido')
        .sort_by { |_, total| -total }
        .first(10)
        .map { |deputado_info, total| 
          {
            id: deputado_info[0],
            nome: deputado_info[1], 
            uf: deputado_info[2],
            partido: deputado_info[3],
            total_gasto: total.to_f
          }
        }
    }

    render json: { data: stats }
  end

  private

  def set_deputado
    @deputado = Deputado.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      message: 'Deputado não encontrado',
      error: 'ID inválido'
    }, status: :not_found
  end
end
