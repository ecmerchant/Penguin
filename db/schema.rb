# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181215150257) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string   "user"
    t.string   "shop_url"
    t.time     "patrol_time"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "condition"
    t.string   "attachment"
    t.integer  "new_price_diff"
    t.integer  "used_price_diff"
    t.string   "label"
    t.integer  "progress"
    t.boolean  "filtered",        default: false, null: false
    t.integer  "search_num"
  end

  create_table "candidates", force: :cascade do |t|
    t.string   "title"
    t.float    "price"
    t.string   "condition"
    t.text     "attachment"
    t.text     "memo"
    t.string   "asin"
    t.string   "jan"
    t.float    "diff_new_price"
    t.float    "diff_used_price"
    t.string   "url"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "user"
    t.string   "item_id"
    t.boolean  "filtered",        default: false, null: false
    t.boolean  "sold",            default: false, null: false
    t.index ["user", "asin", "item_id"], name: "for_upsert_candidate", unique: true, using: :btree
  end

  create_table "labels", force: :cascade do |t|
    t.string   "user"
    t.integer  "number"
    t.string   "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string   "asin"
    t.string   "jan"
    t.string   "title"
    t.float    "new_price"
    t.float    "used_price"
    t.integer  "sales"
    t.boolean  "self_sale"
    t.text     "memo"
    t.string   "label"
    t.string   "delta_link"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "user"
    t.boolean  "filtered",      default: false, null: false
    t.integer  "search_result"
    t.boolean  "sold",          default: false, null: false
    t.index ["user", "asin"], name: "for_upsert", unique: true, using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "admin_flg"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

end
