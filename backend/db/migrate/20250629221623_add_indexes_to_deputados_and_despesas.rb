class AddIndexesToDeputadosAndDespesas < ActiveRecord::Migration[7.2]
  def change
    add_index :deputados, :nome
    add_index :deputados, :uf
    add_index :deputados, :partido
    
    add_index :despesas, :ano
    add_index :despesas, :mes
    add_index :despesas, [:ano, :mes]
    add_index :despesas, :data_emissao
    add_index :despesas, :valor_liquido
    add_index :despesas, :fornecedor
    add_index :despesas, :descricao
  end
end
