class Api::DeputadosController < ApplicationController

  def index
    result = deputados_service.query_deputados(params)

    render json: {
      data: result[:deputados],
      meta: result[:pagination]
    }
  end

  def show
    result = deputados_service.find_deputado(params[:id])
    
    if result
      render json: { data: result }
    else
      render json: { 
        message: 'Deputado não encontrado',
        error: 'ID inválido'
      }, status: :not_found
    end
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

  def deputados_service
    @deputados_service ||= DeputadoService.new
  end
end
