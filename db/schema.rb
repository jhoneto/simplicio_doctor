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

ActiveRecord::Schema[8.0].define(version: 2025_01_03_151736) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bank_account_transactions", force: :cascade do |t|
    t.bigint "bank_account_id"
    t.string "identifier"
    t.string "operation"
    t.decimal "amount"
    t.string "description"
    t.json "original_data"
    t.date "operation_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id"], name: "index_bank_account_transactions_on_bank_account_id"
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "medical_organization_id"
    t.string "name"
    t.string "code"
    t.string "account_number"
    t.string "agency_number"
    t.string "btg_client_id"
    t.string "btg_client_secret"
    t.json "connection_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medical_organization_id"], name: "index_bank_accounts_on_medical_organization_id"
  end

  create_table "banks", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "discounts", force: :cascade do |t|
    t.bigint "payment_id"
    t.string "discount_type", null: false
    t.string "competence", null: false
    t.decimal "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_discounts_on_payment_id"
  end

  create_table "hospital_locals", force: :cascade do |t|
    t.bigint "hospital_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hap_code"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_hospital_locals_on_deleted_at"
    t.index ["hospital_id"], name: "index_hospital_locals_on_hospital_id"
  end

  create_table "hospitals", force: :cascade do |t|
    t.string "cnpj", null: false
    t.string "name", null: false
    t.boolean "prepaid_iss", default: false, null: false
    t.string "address"
    t.string "address_number"
    t.string "address_district"
    t.string "address_compl"
    t.string "address_zipcode"
    t.string "address_city"
    t.string "address_state"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "iss_prepaid", default: false, null: false
    t.string "invoice_email"
    t.string "invoice_phone"
    t.boolean "federal_taxes_prepaid", default: false, null: false
    t.string "ibge_code"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_hospitals_on_deleted_at"
  end

  create_table "invoice_partners", force: :cascade do |t|
    t.bigint "invoice_id"
    t.bigint "medical_organization_partner_id"
    t.decimal "original_value", null: false
    t.decimal "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "open", null: false
    t.decimal "taxes", default: "0.0", null: false
    t.bigint "payment_id"
    t.index ["invoice_id"], name: "index_invoice_partners_on_invoice_id"
    t.index ["medical_organization_partner_id"], name: "index_invoice_partners_on_medical_organization_partner_id"
    t.index ["payment_id"], name: "index_invoice_partners_on_payment_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "medical_organization_id"
    t.bigint "hospital_id"
    t.string "status", default: "pending", null: false
    t.string "competence"
    t.string "cnae"
    t.string "cnae_description"
    t.text "description"
    t.decimal "original_value"
    t.decimal "iss_perc"
    t.boolean "iss_prepaid"
    t.boolean "iss_prepaid_value"
    t.decimal "iss_value"
    t.decimal "value"
    t.integer "rps_number"
    t.integer "rps_serial"
    t.integer "invoice_number"
    t.string "verification_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "invoice_xml"
    t.decimal "ir_value", default: "0.0", null: false
    t.decimal "pis_value", default: "0.0", null: false
    t.decimal "cofins_value", default: "0.0", null: false
    t.decimal "csll_value", default: "0.0", null: false
    t.boolean "validated", default: false, null: false
    t.decimal "ir_value_total", default: "0.0", null: false
    t.decimal "pis_value_total", default: "0.0", null: false
    t.decimal "cofins_value_total", default: "0.0", null: false
    t.decimal "csll_value_total", default: "0.0", null: false
    t.decimal "iss_value_total", default: "0.0", null: false
    t.boolean "federal_taxes_prepaid", default: false, null: false
    t.bigint "hospital_local_id"
    t.datetime "invoice_date", precision: nil
    t.string "due_date"
    t.index ["hospital_id"], name: "index_invoices_on_hospital_id"
    t.index ["hospital_local_id"], name: "index_invoices_on_hospital_local_id"
    t.index ["medical_organization_id"], name: "index_invoices_on_medical_organization_id"
  end

  create_table "medical_organization_activities", force: :cascade do |t|
    t.bigint "medical_organization_id"
    t.string "cnae"
    t.string "cnae_description"
    t.decimal "iss"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medical_organization_id"], name: "actitivy_on_medical_organization_id"
  end

  create_table "medical_organization_partners", force: :cascade do |t|
    t.bigint "medical_organization_id"
    t.string "name", null: false
    t.string "cpf", null: false
    t.string "phone"
    t.string "email"
    t.string "register"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "free_bank_transfer", default: 0, null: false
    t.decimal "fees", default: "0.0", null: false
    t.decimal "taxes", default: "0.0", null: false
    t.string "bank_code"
    t.string "bank_account"
    t.string "bank_agency"
    t.boolean "transfer_tax_free", default: false, null: false
    t.string "hap_code"
    t.datetime "deleted_at", precision: nil
    t.boolean "active", default: true, null: false
    t.string "payment_type", default: "bank_transfer", null: false
    t.string "pix", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["deleted_at"], name: "index_medical_organization_partners_on_deleted_at"
    t.index ["medical_organization_id"], name: "index_medical_organization_partners_on_medical_organization_id"
    t.index ["reset_password_token"], name: "index_medical_organization_partners_on_reset_password_token", unique: true
  end

  create_table "medical_organizations", force: :cascade do |t|
    t.string "status", default: "active", null: false
    t.string "cnpj"
    t.string "social_name", null: false
    t.string "fantasy_name"
    t.string "address"
    t.string "address_number"
    t.string "address_district"
    t.string "address_compl"
    t.string "address_zipcode"
    t.string "address_city"
    t.string "address_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rps_serie", default: "001", null: false
    t.integer "rps_next_number", default: 1, null: false
    t.decimal "bank_transfer_value", default: "0.0", null: false
    t.string "municipal_register"
    t.string "simple_opt"
    t.string "tax_calculation_type", default: "presumed_profit", null: false
    t.string "ibge_code"
    t.string "hap_user"
    t.string "hap_password"
    t.boolean "enabled_nfsehub", default: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_medical_organizations_on_deleted_at"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "medical_organization_partner_id"
    t.date "payment_date", null: false
    t.decimal "total_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medical_organization_partner_id"], name: "index_payments_on_medical_organization_partner_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end
end
