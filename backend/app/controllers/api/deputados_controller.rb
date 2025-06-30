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
    result = deputados_service.get_statistics(params)

    render json: { data: result }
  end

  private

  def deputados_service
    @deputados_service ||= DeputadoService.new
  end
end
