class Despesa < ApplicationRecord
  belongs_to :deputado

  validates :valor_liquido, presence: true, numericality: { greater_than: 0 }
  validates :descricao, presence: true

  scope :por_categoria, ->(categoria) { where("descricao ILIKE ?", "%#{categoria}%") }
  scope :por_mes, ->(mes) { where(mes: mes) }
  scope :por_ano, ->(ano) { where(ano: ano) }
  scope :por_periodo, ->(data_inicio, data_fim) { where(data_emissao: data_inicio..data_fim) }
  scope :valor_acima_de, ->(valor) { where("valor_liquido >= ?", valor) }
  scope :valor_abaixo_de, ->(valor) { where("valor_liquido <= ?", valor) }
  scope :por_fornecedor, ->(fornecedor) { where("fornecedor ILIKE ?", "%#{fornecedor}%") }

  def self.total_por_categoria
    group(:descricao).sum(:valor_liquido)
  end

  def self.total_por_mes
    group(:mes).sum(:valor_liquido)
  end

  def self.total_por_ano
    group(:ano).sum(:valor_liquido)
  end

  def self.fornecedores_top(limit = 10)
    group(:fornecedor)
      .sum(:valor_liquido)
      .sort_by { |_, total| -total }
      .first(limit)
      .to_h
  end

  def self.estatisticas_basicas
    {
      total: sum(:valor_liquido),
      count: count,
      media: average(:valor_liquido),
      valor_maximo: maximum(:valor_liquido),
      valor_minimo: minimum(:valor_liquido)
    }
  end

  def self.por_estado_deputado
    joins(:deputado)
      .group('deputados.uf')
      .sum(:valor_liquido)
  end

  def self.por_partido_deputado
    joins(:deputado)
      .group('deputados.partido')
      .sum(:valor_liquido)
  end
end
