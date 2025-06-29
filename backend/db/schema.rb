# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_06_29_221623) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "deputados", force: :cascade do |t|
    t.string "nome"
    t.string "cpf"
    t.string "carteira_parlamentar"
    t.string "uf"
    t.string "partido"
    t.integer "deputado_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deputado_id"], name: "index_deputados_on_deputado_id", unique: true
    t.index ["nome"], name: "index_deputados_on_nome"
    t.index ["partido"], name: "index_deputados_on_partido"
    t.index ["uf"], name: "index_deputados_on_uf"
  end

  create_table "despesas", force: :cascade do |t|
    t.bigint "deputado_id", null: false
    t.string "descricao"
    t.string "especificacao"
    t.string "fornecedor"
    t.string "cnpj_cpf_fornecedor"
    t.string "numero_documento"
    t.integer "tipo_documento"
    t.date "data_emissao"
    t.decimal "valor_documento"
    t.decimal "valor_glosa"
    t.decimal "valor_liquido"
    t.integer "mes"
    t.integer "ano"
    t.integer "parcela"
    t.string "passageiro"
    t.string "trecho"
    t.string "lote"
    t.string "url_documento"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ano", "mes"], name: "index_despesas_on_ano_and_mes"
    t.index ["ano"], name: "index_despesas_on_ano"
    t.index ["data_emissao"], name: "index_despesas_on_data_emissao"
    t.index ["deputado_id"], name: "index_despesas_on_deputado_id"
    t.index ["descricao"], name: "index_despesas_on_descricao"
    t.index ["fornecedor"], name: "index_despesas_on_fornecedor"
    t.index ["mes"], name: "index_despesas_on_mes"
    t.index ["valor_liquido"], name: "index_despesas_on_valor_liquido"
  end

  add_foreign_key "despesas", "deputados"
end
