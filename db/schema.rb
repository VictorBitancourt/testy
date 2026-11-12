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

ActiveRecord::Schema[8.1].define(version: 2026_11_11_200000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.text "caption"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "bug_analyses", force: :cascade do |t|
    t.string "ai_model"
    t.string "ai_provider"
    t.integer "bug_count", null: false
    t.json "cause_counts", null: false
    t.datetime "created_at", null: false
    t.json "feature_counts", null: false
    t.json "patterns", null: false
    t.integer "project_id", null: false
    t.json "recommendations", null: false
    t.text "summary", null: false
    t.integer "total_bugs", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["project_id"], name: "index_bug_analyses_on_project_id"
    t.index ["user_id"], name: "index_bug_analyses_on_user_id"
  end

  create_table "bugs", force: :cascade do |t|
    t.string "cause_tag"
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.text "expected_result"
    t.string "feature_tag"
    t.text "obtained_result"
    t.integer "project_id", null: false
    t.string "status", default: "open", null: false
    t.text "steps_to_reproduce"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["project_id"], name: "index_bugs_on_project_id"
    t.index ["user_id"], name: "index_bugs_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["name"], name: "index_projects_on_name", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "ai_model"
    t.string "ai_provider"
    t.text "anthropic_api_key"
    t.datetime "created_at", null: false
    t.text "gemini_api_key"
    t.text "openai_api_key"
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "test_plan_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.integer "test_plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_test_plan_tags_on_tag_id"
    t.index ["test_plan_id", "tag_id"], name: "index_test_plan_tags_on_test_plan_id_and_tag_id", unique: true
    t.index ["test_plan_id"], name: "index_test_plan_tags_on_test_plan_id"
  end

  create_table "test_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "project_id", null: false
    t.string "qa_name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["project_id"], name: "index_test_plans_on_project_id"
    t.index ["user_id"], name: "index_test_plans_on_user_id"
  end

  create_table "test_scenarios", force: :cascade do |t|
    t.integer "bug_id"
    t.datetime "created_at", null: false
    t.text "given"
    t.integer "position"
    t.string "status", default: "pending", null: false
    t.integer "test_plan_id", null: false
    t.text "then_step"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.text "when_step"
    t.index ["bug_id"], name: "index_test_scenarios_on_bug_id"
    t.index ["position"], name: "index_test_scenarios_on_position"
    t.index ["test_plan_id"], name: "index_test_scenarios_on_test_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "bug_analyses", "projects"
  add_foreign_key "bug_analyses", "users"
  add_foreign_key "bugs", "projects"
  add_foreign_key "bugs", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "test_plan_tags", "tags"
  add_foreign_key "test_plan_tags", "test_plans"
  add_foreign_key "test_plans", "projects"
  add_foreign_key "test_plans", "users"
  add_foreign_key "test_scenarios", "bugs"
  add_foreign_key "test_scenarios", "test_plans"
end
