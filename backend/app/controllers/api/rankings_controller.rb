class Api::RankingsController < ApplicationController
  def index
    @ranking = calculate_ranking
    
    render json: {
      data: @ranking,
      meta: {
        ranking_type: params[:tipo] || 'gastos_totais',
        period: get_period_description,
        generated_at: Time.current
      }
    }
  end

  def gastos_totais
    filters = build_base_filters
    
    ranking = Deputado.joins(:despesas)
      .where(filters[:deputados_where])
      .where(despesas: filters[:despesas_where])
      .group('deputados.id', 'deputados.nome', 'deputados.uf', 'deputados.partido')
      .sum('despesas.valor_liquido')
      .sort_by { |_, total| -total }
      .first(params[:limit]&.to_i || 50)
      .map.with_index(1) do |(deputado_info, total), position|
        {
          posicao: position,
          deputado: {
            id: deputado_info[0],
            nome: deputado_info[1],
            uf: deputado_info[2],
            partido: deputado_info[3]
          },
          total_gasto: total.to_f,
          documentos_count: get_documents_count(deputado_info[0], filters)
        }
      end
    
    render json: { data: ranking }
  end

  def por_categoria
    categoria = params[:categoria] || get_top_category
    filters = build_base_filters
    
    ranking = Deputado.joins(:despesas)
      .where(filters[:deputados_where])
      .where(despesas: filters[:despesas_where])
      .where("despesas.descricao ILIKE ?", "%#{categoria}%")
      .group('deputados.id', 'deputados.nome', 'deputados.uf', 'deputados.partido')
      .sum('despesas.valor_liquido')
      .sort_by { |_, total| -total }
      .first(params[:limit]&.to_i || 30)
      .map.with_index(1) do |(deputado_info, total), position|
        {
          posicao: position,
          deputado: {
            id: deputado_info[0],
            nome: deputado_info[1],
            uf: deputado_info[2],
            partido: deputado_info[3]
          },
          total_gasto: total.to_f,
          categoria: categoria
        }
      end
    
    render json: { 
      data: ranking,
      meta: { categoria: categoria }
    }
  end

  def por_estado
    uf = params[:uf]
    
    if uf.present?
      ranking = ranking_por_uf_especifica(uf)
      render json: { 
        data: ranking,
        meta: { uf: uf }
      }
    else
      ranking = ranking_geral_por_estados
      render json: { data: ranking }
    end
  end

  def por_partido
    partido = params[:partido]
    
    if partido.present?
      ranking = ranking_por_partido_especifico(partido)
      render json: { 
        data: ranking,
        meta: { partido: partido }
      }
    else
      ranking = ranking_geral_por_partidos
      render json: { data: ranking }
    end
  end

  def eficiencia_gastos
    filters = build_base_filters
    min_documentos = params[:min_documentos]&.to_i || 10
    
    ranking = Deputado.joins(:despesas)
      .where(filters[:deputados_where])
      .where(despesas: filters[:despesas_where])
      .group('deputados.id', 'deputados.nome', 'deputados.uf', 'deputados.partido')
      .having('COUNT(despesas.id) >= ?', min_documentos)
      .sum('despesas.valor_liquido')
      .sort_by { |_, total| total }  # Sort ascending for efficiency
      .first(params[:limit]&.to_i || 30)
      .map.with_index(1) do |(deputado_info, total), position|
        {
          posicao: position,
          deputado: {
            id: deputado_info[0],
            nome: deputado_info[1],
            uf: deputado_info[2],
            partido: deputado_info[3]
          },
          total_gasto: total.to_f,
          documentos_count: get_documents_count(deputado_info[0], filters),
          gasto_por_documento: (total.to_f / get_documents_count(deputado_info[0], filters)).round(2)
        }
      end
    
    render json: { 
      data: ranking,
      meta: { 
        tipo: 'eficiencia',
        criterio: 'menor_gasto_com_atividade_minima',
        min_documentos: min_documentos
      }
    }
  end

  def comparativo_temporal
    # Temporal comparison ranking
    ano_atual = params[:ano_atual]&.to_i || Date.current.year
    ano_anterior = params[:ano_anterior]&.to_i || (ano_atual - 1)
    
    ranking = build_temporal_comparison(ano_atual, ano_anterior)
    
    render json: { 
      data: ranking,
      meta: {
        ano_atual: ano_atual,
        ano_anterior: ano_anterior
      }
    }
  end

  private

  def calculate_ranking
    case params[:tipo]
    when 'por_categoria'
      categoria = params[:categoria] || get_top_category
      filters = build_base_filters
      
      Deputado.joins(:despesas)
        .where(filters[:deputados_where])
        .where(despesas: filters[:despesas_where])
        .where("despesas.descricao ILIKE ?", "%#{categoria}%")
        .group('deputados.id', 'deputados.nome', 'deputados.uf', 'deputados.partido')
        .sum('despesas.valor_liquido')
        .sort_by { |_, total| -total }
        .first(params[:limit]&.to_i || 30)
        .map.with_index(1) do |(deputado_info, total), position|
          {
            posicao: position,
            deputado: {
              id: deputado_info[0],
              nome: deputado_info[1],
              uf: deputado_info[2],
              partido: deputado_info[3]
            },
            total_gasto: total.to_f,
            categoria: categoria
          }
        end
    when 'por_estado'
      uf = params[:uf]
      if uf.present?
        ranking_por_uf_especifica(uf)
      else
        ranking_geral_por_estados
      end
    when 'por_partido'
      partido = params[:partido]
      if partido.present?
        ranking_por_partido_especifico(partido)
      else
        ranking_geral_por_partidos
      end
    when 'eficiencia'
      filters = build_base_filters
      min_documentos = params[:min_documentos]&.to_i || 10
      
      Deputado.joins(:despesas)
        .where(filters[:deputados_where])
        .where(despesas: filters[:despesas_where])
        .group('deputados.id', 'deputados.nome', 'deputados.uf', 'deputados.partido')
        .having('COUNT(despesas.id) >= ?', min_documentos)
        .sum('despesas.valor_liquido')
        .sort_by { |_, total| total }
        .first(params[:limit]&.to_i || 30)
        .map.with_index(1) do |(deputado_info, total), position|
          {
            posicao: position,
            deputado: {
              id: deputado_info[0],
              nome: deputado_info[1],
              uf: deputado_info[2],
              partido: deputado_info[3]
            },
            total_gasto: total.to_f,
            documentos_count: get_documents_count(deputado_info[0], filters),
            gasto_por_documento: (total.to_f / get_documents_count(deputado_info[0], filters)).round(2)
          }
        end
    else
      # gastos_totais
      filters = build_base_filters
      
      Deputado.joins(:despesas)
        .where(filters[:deputados_where])
        .where(despesas: filters[:despesas_where])
        .group('deputados.id', 'deputados.nome', 'deputados.uf', 'deputados.partido')
        .sum('despesas.valor_liquido')
        .sort_by { |_, total| -total }
        .first(params[:limit]&.to_i || 50)
        .map.with_index(1) do |(deputado_info, total), position|
          {
            posicao: position,
            deputado: {
              id: deputado_info[0],
              nome: deputado_info[1],
              uf: deputado_info[2],
              partido: deputado_info[3]
            },
            total_gasto: total.to_f,
            documentos_count: get_documents_count(deputado_info[0], filters)
          }
        end
    end
  end

  def build_base_filters
    deputados_where = {}
    despesas_where = {}
    
    deputados_where[:uf] = params[:uf] if params[:uf].present?
    deputados_where[:partido] = params[:partido] if params[:partido].present?
    
    despesas_where[:ano] = params[:ano] if params[:ano].present?
    despesas_where[:mes] = params[:mes] if params[:mes].present?
    
    {
      deputados_where: deputados_where,
      despesas_where: despesas_where
    }
  end

  def get_documents_count(deputado_id, filters)
    Despesa.where(deputado_id: deputado_id)
      .where(filters[:despesas_where])
      .count
  end

  def get_top_category
    Despesa.group(:descricao)
      .sum(:valor_liquido)
      .max_by { |_, total| total }
      &.first || 'MANUTENÇÃO DE ESCRITÓRIO'
  end

  def get_period_description
    if params[:ano].present?
      if params[:mes].present?
        "#{params[:mes]}/#{params[:ano]}"
      else
        params[:ano]
      end
    else
      "Todos os períodos"
    end
  end

  def ranking_por_uf_especifica(uf)
    filters = build_base_filters
    filters[:deputados_where][:uf] = uf
    
    Deputado.joins(:despesas)
      .where(filters[:deputados_where])
      .where(despesas: filters[:despesas_where])
      .group('deputados.id', 'deputados.nome', 'deputados.partido')
      .sum('despesas.valor_liquido')
      .sort_by { |_, total| -total }
      .first(params[:limit]&.to_i || 20)
      .map.with_index(1) do |(deputado_info, total), position|
        {
          posicao: position,
          deputado: {
            id: deputado_info[0],
            nome: deputado_info[1],
            partido: deputado_info[2],
            uf: uf
          },
          total_gasto: total.to_f
        }
      end
  end

  def ranking_geral_por_estados
    filters = build_base_filters
    
    Deputado.joins(:despesas)
      .where(filters[:deputados_where])
      .where(despesas: filters[:despesas_where])
      .group('deputados.uf')
      .sum('despesas.valor_liquido')
      .sort_by { |_, total| -total }
      .map.with_index(1) do |(uf, total), position|
        deputados_count = Deputado.where(uf: uf).count
        {
          posicao: position,
          uf: uf,
          total_gasto: total.to_f,
          deputados_count: deputados_count,
          gasto_medio_por_deputado: deputados_count > 0 ? (total.to_f / deputados_count).round(2) : 0
        }
      end
  end

  def ranking_por_partido_especifico(partido)
    filters = build_base_filters
    filters[:deputados_where][:partido] = partido
    
    Deputado.joins(:despesas)
      .where(filters[:deputados_where])
      .where(despesas: filters[:despesas_where])
      .group('deputados.id', 'deputados.nome', 'deputados.uf')
      .sum('despesas.valor_liquido')
      .sort_by { |_, total| -total }
      .first(params[:limit]&.to_i || 20)
      .map.with_index(1) do |(deputado_info, total), position|
        {
          posicao: position,
          deputado: {
            id: deputado_info[0],
            nome: deputado_info[1],
            uf: deputado_info[2],
            partido: partido
          },
          total_gasto: total.to_f
        }
      end
  end

  def ranking_geral_por_partidos
    filters = build_base_filters
    
    Deputado.joins(:despesas)
      .where(filters[:deputados_where])
      .where(despesas: filters[:despesas_where])
      .group('deputados.partido')
      .sum('despesas.valor_liquido')
      .sort_by { |_, total| -total }
      .map.with_index(1) do |(partido, total), position|
        deputados_count = Deputado.where(partido: partido).count
        {
          posicao: position,
          partido: partido,
          total_gasto: total.to_f,
          deputados_count: deputados_count,
          gasto_medio_por_deputado: deputados_count > 0 ? (total.to_f / deputados_count).round(2) : 0
        }
      end
  end

  def build_temporal_comparison(ano_atual, ano_anterior)
    gastos_atual = get_gastos_por_ano(ano_atual)
    gastos_anterior = get_gastos_por_ano(ano_anterior)
    
    all_deputados = (gastos_atual.keys + gastos_anterior.keys).uniq
    
    comparison = all_deputados.map do |deputado_id|
      deputado = Deputado.find(deputado_id)
      gasto_atual = gastos_atual[deputado_id] || 0
      gasto_anterior = gastos_anterior[deputado_id] || 0
      
      variacao = gasto_anterior > 0 ? ((gasto_atual - gasto_anterior) / gasto_anterior * 100).round(2) : nil
      
      {
        deputado: {
          id: deputado.id,
          nome: deputado.nome,
          uf: deputado.uf,
          partido: deputado.partido
        },
        gasto_atual: gasto_atual.to_f,
        gasto_anterior: gasto_anterior.to_f,
        variacao_percentual: variacao,
        diferenca_absoluta: (gasto_atual - gasto_anterior).to_f
      }
    end
    
    comparison.sort_by { |item| -item[:diferenca_absoluta] }.first(50)
  end

  def get_gastos_por_ano(ano)
    Deputado.joins(:despesas)
      .where(despesas: { ano: ano })
      .group('deputados.id')
      .sum('despesas.valor_liquido')
  end
end
