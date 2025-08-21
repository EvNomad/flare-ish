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

ActiveRecord::Schema[8.0].define(version: 2025_08_20_120500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "time_slot_id", null: false
    t.bigint "client_id", null: false
    t.string "status", default: "held", null: false
    t.datetime "hold_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_event_id"
    t.string "external_calendar_source"
    t.string "external_calendar_status"
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["provider_id", "external_event_id"], name: "index_bookings_on_provider_id_and_external_event_id", unique: true, where: "(external_event_id IS NOT NULL)"
    t.index ["provider_id", "time_slot_id", "status"], name: "idx_unique_active_booking", unique: true, where: "((status)::text = ANY ((ARRAY['held'::character varying, 'submitted'::character varying, 'accepted'::character varying])::text[]))"
    t.index ["provider_id", "time_slot_id"], name: "index_bookings_on_provider_id_and_time_slot_id"
    t.index ["provider_id"], name: "index_bookings_on_provider_id"
    t.index ["time_slot_id"], name: "index_bookings_on_time_slot_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_clients_on_email", unique: true
  end

  create_table "external_blocks", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "source", default: "admin", null: false
    t.string "external_event_id"
    t.datetime "start_utc", null: false
    t.datetime "end_utc", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "external_event_id"], name: "index_external_blocks_on_provider_id_and_external_event_id", unique: true, where: "(external_event_id IS NOT NULL)"
    t.index ["provider_id", "start_utc", "end_utc"], name: "index_external_blocks_on_provider_id_and_start_utc_and_end_utc"
    t.index ["provider_id"], name: "index_external_blocks_on_provider_id"
  end

  create_table "provider_time_slots", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "time_slot_id", null: false
    t.string "state", default: "open", null: false
    t.string "source", default: "template", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "state"], name: "index_provider_time_slots_on_provider_id_and_state"
    t.index ["provider_id", "time_slot_id"], name: "index_provider_time_slots_on_provider_id_and_time_slot_id", unique: true
    t.index ["provider_id"], name: "index_provider_time_slots_on_provider_id"
    t.index ["time_slot_id"], name: "index_provider_time_slots_on_time_slot_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "tz", null: false
    t.string "email", null: false
    t.integer "service_type", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_providers_on_email", unique: true
  end

  create_table "time_slots", id: :string, force: :cascade do |t|
    t.string "tz", null: false
    t.date "local_date", null: false
    t.time "local_time", null: false
    t.datetime "start_utc", null: false
    t.datetime "end_utc", null: false
    t.integer "fold", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tz", "local_date", "local_time", "fold"], name: "index_time_slots_identity", unique: true
    t.index ["tz", "start_utc"], name: "index_time_slots_on_tz_and_start_utc"
  end

  create_table "weekly_templates", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.integer "dow", null: false
    t.time "start_local", null: false
    t.time "end_local", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "dow"], name: "index_weekly_templates_on_provider_id_and_dow"
    t.index ["provider_id"], name: "index_weekly_templates_on_provider_id"
  end

  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "providers"
  add_foreign_key "bookings", "time_slots"
  add_foreign_key "external_blocks", "providers"
  add_foreign_key "provider_time_slots", "providers"
  add_foreign_key "provider_time_slots", "time_slots"
  add_foreign_key "weekly_templates", "providers"
end
