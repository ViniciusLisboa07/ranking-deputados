class Deputado < ApplicationRecord
  has_many :despesas, dependent: :destroy

  validates :nome, presence: true
  validates :deputado_id, presence: true, uniqueness: true

  scope :por_uf, ->(uf) { where(uf: uf) }
  scope :por_partido, ->(partido) { where(partido: partido) }
  scope :com_despesas, -> { joins(:despesas).distinct }

  def total_despesas
    despesas.sum(:valor_liquido)
  end

  def total_documentos
    despesas.count
  end

  def gasto_medio_por_documento
    return 0 if despesas.count == 0
    total_despesas / despesas.count
  end

  def despesas_por_categoria
    despesas.group(:descricao).sum(:valor_liquido)
  end

  def despesas_por_mes
    despesas.group(:mes).sum(:valor_liquido)
  end

  def self.ranking_gastos(limit = 50)
    joins(:despesas)
      .group('deputados.id')
      .order('SUM(despesas.valor_liquido) DESC')
      .limit(limit)
  end

  def self.por_estado_resumo
    group(:uf).count
  end

  def self.por_partido_resumo
    group(:partido).count
  end
end
