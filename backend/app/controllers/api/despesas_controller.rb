class Api::DespesasController < ApplicationController
  before_action :set_despesa, only: [:show]

  def index
    @despesas = Despesa.includes(:deputado)

    @despesas = @despesas.where(deputado_id: params[:deputado_id]) if params[:deputado_id].present?
    @despesas = @despesas.joins(:deputado).where(deputados: { uf: params[:uf] }) if params[:uf].present?
    @despesas = @despesas.joins(:deputado).where(deputados: { partido: params[:partido] }) if params[:partido].present?
    @despesas = @despesas.where(mes: params[:mes]) if params[:mes].present?
    @despesas = @despesas.where(ano: params[:ano]) if params[:ano].present?
    @despesas = @despesas.where("descricao ILIKE ?", "%#{params[:categoria]}%") if params[:categoria].present?

    if params[:data_inicio].present? && params[:data_fim].present?
      begin
        data_inicio = Date.parse(params[:data_inicio])
        data_fim = Date.parse(params[:data_fim])
        @despesas = @despesas.where(data_emissao: data_inicio..data_fim)
      rescue Date::Error
        puts "Data inválida: #{params[:data_inicio]} ou #{params[:data_fim]}"
      end
    end

    if params[:valor_min].present?
      @despesas = @despesas.where("valor_liquido >= ?", params[:valor_min].to_f)
    end
    
    if params[:valor_max].present?
      @despesas = @despesas.where("valor_liquido <= ?", params[:valor_max].to_f)
    end

    if params[:fornecedor].present?
      @despesas = @despesas.where("fornecedor ILIKE ?", "%#{params[:fornecedor]}%")
    end

    case params[:order_by]
    when 'valor'
      @despesas = @despesas.order(valor_liquido: :desc)
    when 'data'
      @despesas = @despesas.order(data_emissao: :desc)
    when 'deputado'
      @despesas = @despesas.joins(:deputado).order('deputados.nome')
    when 'categoria'
      @despesas = @despesas.order(:descricao)
    else
      @despesas = @despesas.order(created_at: :desc)
    end

    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min
    offset = (page - 1) * per_page

    total_count = @despesas.count
    @despesas = @despesas.limit(per_page).offset(offset)

    despesas_data = @despesas.map do |despesa|
      {
        id: despesa.id,
        deputado: {
          id: despesa.deputado.id,
          nome: despesa.deputado.nome,
          uf: despesa.deputado.uf,
          partido: despesa.deputado.partido
        },
        descricao: despesa.descricao,
        especificacao: despesa.especificacao,
        fornecedor: despesa.fornecedor,
        cnpj_cpf_fornecedor: despesa.cnpj_cpf_fornecedor,
        numero_documento: despesa.numero_documento,
        data_emissao: despesa.data_emissao,
        valor_documento: despesa.valor_documento&.to_f,
        valor_glosa: despesa.valor_glosa&.to_f,
        valor_liquido: despesa.valor_liquido&.to_f,
        mes: despesa.mes,
        ano: despesa.ano,
        url_documento: despesa.url_documento
      }
    end

    render json: {
      data: despesas_data,
      meta: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  def show
    despesa_data = {
      id: @despesa.id,
      deputado: {
        id: @despesa.deputado.id,
        nome: @despesa.deputado.nome,
        cpf: @despesa.deputado.cpf,
        uf: @despesa.deputado.uf,
        partido: @despesa.deputado.partido,
        carteira_parlamentar: @despesa.deputado.carteira_parlamentar
      },
      descricao: @despesa.descricao,
      especificacao: @despesa.especificacao,
      fornecedor: @despesa.fornecedor,
      cnpj_cpf_fornecedor: @despesa.cnpj_cpf_fornecedor,
      numero_documento: @despesa.numero_documento,
      tipo_documento: @despesa.tipo_documento,
      data_emissao: @despesa.data_emissao,
      valor_documento: @despesa.valor_documento&.to_f,
      valor_glosa: @despesa.valor_glosa&.to_f,
      valor_liquido: @despesa.valor_liquido&.to_f,
      mes: @despesa.mes,
      ano: @despesa.ano,
      parcela: @despesa.parcela,
      passageiro: @despesa.passageiro,
      trecho: @despesa.trecho,
      lote: @despesa.lote,
      url_documento: @despesa.url_documento,
      created_at: @despesa.created_at,
      updated_at: @despesa.updated_at
    }

    render json: { data: despesa_data }
  end

  def summary
    base_query = Despesa.includes(:deputado)
    
    base_query = apply_filters(base_query)

    summary_data = {
      total_despesas: base_query.sum(:valor_liquido).to_f,
      total_documentos: base_query.count,
      valor_medio: base_query.average(:valor_liquido)&.to_f || 0,
      valor_mediano: calculate_median(base_query.pluck(:valor_liquido)),
      despesas_por_categoria: base_query.group(:descricao)
        .sum(:valor_liquido)
        .transform_values { |v| v.to_f }
        .sort_by { |_, v| -v }
        .first(10)
        .to_h,
      despesas_por_mes: base_query.group(:mes)
        .sum(:valor_liquido)
        .transform_values { |v| v.to_f },
      fornecedores_top: base_query.group(:fornecedor)
        .sum(:valor_liquido)
        .transform_values { |v| v.to_f }
        .sort_by { |_, v| -v }
        .first(10)
        .to_h
    }

    render json: { data: summary_data }
  end

  private

  def set_despesa
    @despesa = Despesa.includes(:deputado).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      message: 'Despesa não encontrada',
      error: 'ID inválido'
    }, status: :not_found
  end

  def apply_filters(query)
    query = query.where(deputado_id: params[:deputado_id]) if params[:deputado_id].present?
    query = query.joins(:deputado).where(deputados: { uf: params[:uf] }) if params[:uf].present?
    query = query.joins(:deputado).where(deputados: { partido: params[:partido] }) if params[:partido].present?
    query = query.where(mes: params[:mes]) if params[:mes].present?
    query = query.where(ano: params[:ano]) if params[:ano].present?
    query = query.where("descricao ILIKE ?", "%#{params[:categoria]}%") if params[:categoria].present?

    if params[:data_inicio].present? && params[:data_fim].present?
      begin
        data_inicio = Date.parse(params[:data_inicio])
        data_fim = Date.parse(params[:data_fim])
        query = query.where(data_emissao: data_inicio..data_fim)
      rescue Date::Error
        puts "Data inválida: #{params[:data_inicio]} ou #{params[:data_fim]}"
      end
    end

    query = query.where("valor_liquido >= ?", params[:valor_min].to_f) if params[:valor_min].present?
    query = query.where("valor_liquido <= ?", params[:valor_max].to_f) if params[:valor_max].present?
    query = query.where("fornecedor ILIKE ?", "%#{params[:fornecedor]}%") if params[:fornecedor].present?

    query
  end

  def calculate_median(values)
    return 0 if values.empty?
    
    sorted = values.map(&:to_f).sort
    length = sorted.length
    
    if length.odd?
      sorted[length / 2]
    else
      (sorted[length / 2 - 1] + sorted[length / 2]) / 2.0
    end
  end
end
