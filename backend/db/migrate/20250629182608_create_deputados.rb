class CreateDeputados < ActiveRecord::Migration[7.2]
  def change
    create_table :deputados do |t|
      t.string :nome
      t.string :cpf
      t.string :carteira_parlamentar
      t.string :uf
      t.string :partido
      t.integer :deputado_id

      t.timestamps
    end
  end
end
