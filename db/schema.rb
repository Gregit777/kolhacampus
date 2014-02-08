# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140129091220) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "articles", force: true do |t|
    t.string   "title",                             null: false
    t.string   "subtitle",                          null: false
    t.string   "image"
    t.text     "body"
    t.datetime "publish_at",                        null: false
    t.text     "tags"
    t.integer  "status",     limit: 1,  default: 1, null: false
    t.string   "old_id",     limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "articles", ["old_id"], name: "index_articles_on_old_id", unique: true, using: :btree

  create_table "articles_categories", id: false, force: true do |t|
    t.integer "article_id",  null: false
    t.integer "category_id", null: false
  end

  add_index "articles_categories", ["article_id"], name: "index_articles_categories_on_article_id", using: :btree
  add_index "articles_categories", ["category_id"], name: "index_articles_categories_on_category_id", using: :btree

  create_table "articles_users", id: false, force: true do |t|
    t.integer "article_id", null: false
    t.integer "user_id",    null: false
  end

  add_index "articles_users", ["article_id"], name: "index_articles_users_on_article_id", using: :btree
  add_index "articles_users", ["user_id"], name: "index_articles_users_on_user_id", using: :btree

  create_table "categories", force: true do |t|
    t.string "name",     null: false
    t.string "bg_color"
    t.string "icon"
  end

  add_index "categories", ["name"], name: "index_categories_on_name", unique: true, using: :btree

  create_table "categories_events", id: false, force: true do |t|
    t.integer "event_id",    null: false
    t.integer "category_id", null: false
  end

  add_index "categories_events", ["category_id"], name: "index_categories_events_on_category_id", using: :btree
  add_index "categories_events", ["event_id"], name: "index_categories_events_on_event_id", using: :btree

  create_table "configuration", force: true do |t|
    t.string "name", null: false
    t.text   "data", null: false
  end

  add_index "configuration", ["name"], name: "index_configuration_on_name", unique: true, using: :btree

  create_table "events", force: true do |t|
    t.string   "title",                               null: false
    t.string   "subtitle",                            null: false
    t.string   "image"
    t.text     "body"
    t.datetime "starts_at",                           null: false
    t.datetime "ends_at",                             null: false
    t.string   "location"
    t.string   "map",        limit: 2048
    t.text     "tags"
    t.integer  "status",     limit: 1,    default: 1, null: false
    t.string   "old_id",     limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["old_id"], name: "index_events_on_old_id", unique: true, using: :btree

  create_table "events_users", id: false, force: true do |t|
    t.integer "event_id", null: false
    t.integer "user_id",  null: false
  end

  add_index "events_users", ["event_id"], name: "index_events_users_on_event_id", using: :btree
  add_index "events_users", ["user_id"], name: "index_events_users_on_user_id", using: :btree

  create_table "programs", force: true do |t|
    t.string   "name",                                       null: false
    t.string   "name_en"
    t.text     "description"
    t.string   "image"
    t.boolean  "active",                     default: false
    t.boolean  "live",                       default: false
    t.integer  "status",           limit: 1, default: 1,     null: false
    t.integer  "icast_program_id"
    t.boolean  "is_set",                     default: false, null: false
    t.integer  "tracklist_count",            default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "programs", ["icast_program_id"], name: "index_programs_on_icast_program_id", unique: true, using: :btree
  add_index "programs", ["status"], name: "index_programs_on_status", using: :btree

  create_table "programs_users", id: false, force: true do |t|
    t.integer "program_id", null: false
    t.integer "user_id",    null: false
  end

  add_index "programs_users", ["program_id", "user_id"], name: "index_programs_users_on_program_id_and_user_id", unique: true, using: :btree
  add_index "programs_users", ["user_id", "program_id"], name: "index_programs_users_on_user_id_and_program_id", unique: true, using: :btree

  create_table "raw_tracklists", force: true do |t|
    t.string   "source",   null: false
    t.text     "results"
    t.datetime "last_run"
  end

  create_table "schedules", force: true do |t|
    t.string   "title",                                      null: false
    t.string   "description",   limit: 1024
    t.text     "configuration",                              null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "is_default",                 default: false, null: false
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: true do |t|
    t.string "name"
  end

  create_table "tracklists", force: true do |t|
    t.integer  "program_id",                                    null: false
    t.text     "description",    limit: 255
    t.text     "description_en", limit: 255
    t.datetime "publish_at",                                    null: false
    t.text     "tracks",         limit: 2147483647
    t.text     "feed",           limit: 2147483647
    t.string   "ondemand_url"
    t.integer  "status",         limit: 1,          default: 1, null: false
    t.string   "token",          limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tracklists", ["program_id", "publish_at"], name: "index_tracklists_on_program_id_and_publish_at", using: :btree
  add_index "tracklists", ["publish_at", "program_id"], name: "index_tracklists_on_publish_at_and_program_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "first_name",                                                null: false
    t.string   "last_name",                                                 null: false
    t.string   "first_name_en"
    t.string   "last_name_en"
    t.string   "email",                                   default: "",      null: false
    t.text     "about",                  limit: 16777215
    t.string   "image"
    t.integer  "status",                 limit: 1,        default: 1,       null: false
    t.boolean  "active",                                  default: false,   null: false
    t.string   "token"
    t.integer  "roles_mask",                              default: 0,       null: false
    t.string   "encrypted_password",                      default: "",      null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                           default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 16
    t.string   "last_sign_in_ip",        limit: 16
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider",               limit: 64,       default: "106fm"
    t.string   "uid"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
