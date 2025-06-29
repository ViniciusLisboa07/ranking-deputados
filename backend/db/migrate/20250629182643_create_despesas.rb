class CreateDespesas < ActiveRecord::Migration[7.2]
  def change
    create_table :despesas do |t|
      t.references :deputado, null: false, foreign_key: true
      t.string :descricao
      t.string :especificacao
      t.string :fornecedor
      t.string :cnpj_cpf_fornecedor
      t.string :numero_documento
      t.integer :tipo_documento
      t.date :data_emissao
      t.decimal :valor_documento
      t.decimal :valor_glosa
      t.decimal :valor_liquido
      t.integer :mes
      t.integer :ano
      t.integer :parcela
      t.string :passageiro
      t.string :trecho
      t.string :lote
      t.string :url_documento

      t.timestamps
    end
  end
end
