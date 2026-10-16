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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_170400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "agent_runs", force: :cascade do |t|
    t.string "agent_type", null: false
    t.string "status", null: false
    t.string "source", null: false
    t.string "model"
    t.string "subject_type"
    t.bigint "subject_id"
    t.bigint "user_id"
    t.integer "tokens_in", default: 0, null: false
    t.integer "tokens_out", default: 0, null: false
    t.integer "latency_ms"
    t.decimal "cost_usd", precision: 12, scale: 8, default: "0.0", null: false
    t.jsonb "output", default: {}, null: false
    t.string "error_summary"
    t.string "provider_request_id"
    t.datetime "applied_at"
    t.bigint "applied_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_type", "created_at"], name: "index_agent_runs_on_agent_type_and_created_at"
    t.index ["applied_by_id"], name: "index_agent_runs_on_applied_by_id"
    t.index ["subject_type", "subject_id"], name: "index_agent_runs_on_subject"
    t.index ["user_id"], name: "index_agent_runs_on_user_id"
    t.check_constraint "source::text = ANY (ARRAY['openai'::character varying::text, 'fallback'::character varying::text, 'fake'::character varying::text, 'none'::character varying::text])", name: "agent_runs_source_check"
    t.check_constraint "status::text = ANY (ARRAY['succeeded'::character varying::text, 'failed'::character varying::text])", name: "agent_runs_status_check"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target_type_and_target_id"
  end

  create_table "automation_rules", force: :cascade do |t|
    t.string "name", null: false
    t.string "event", null: false
    t.jsonb "conditions", default: {}, null: false
    t.jsonb "actions", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event", "position"], name: "index_automation_rules_on_event_and_position"
    t.check_constraint "event::text = ANY (ARRAY['ticket_created'::character varying::text, 'ticket_updated'::character varying::text])", name: "automation_rules_event_check"
  end

  create_table "csat_ratings", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "customer_id", null: false
    t.integer "score", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_csat_ratings_on_customer_id"
    t.index ["ticket_id"], name: "index_csat_ratings_on_ticket_id", unique: true
    t.check_constraint "score >= 1 AND score <= 5", name: "csat_ratings_score_check"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "company"
    t.string "tier", default: "standard", null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_customers_on_lower_email", unique: true
    t.check_constraint "tier::text = ANY (ARRAY['standard'::character varying::text, 'pro'::character varying::text, 'enterprise'::character varying::text])", name: "customers_tier_check"
  end

  create_table "incident_tickets", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "ticket_id", null: false
    t.decimal "similarity", precision: 4, scale: 3
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id", "ticket_id"], name: "index_incident_tickets_on_incident_id_and_ticket_id", unique: true
    t.index ["incident_id"], name: "index_incident_tickets_on_incident_id"
    t.index ["ticket_id"], name: "index_incident_tickets_on_ticket_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.string "title", null: false
    t.text "summary", null: false
    t.text "suspected_root_cause"
    t.string "severity", default: "medium", null: false
    t.string "status", default: "proposed", null: false
    t.decimal "confidence", precision: 4, scale: 3
    t.text "uncertainty"
    t.string "product"
    t.jsonb "symptoms", default: [], null: false
    t.jsonb "evidence", default: [], null: false
    t.jsonb "suggested_actions", default: [], null: false
    t.jsonb "resolution_plan", default: {}, null: false
    t.text "recommended_next_action"
    t.text "resolution_note"
    t.bigint "detected_by_run_id"
    t.bigint "confirmed_by_id"
    t.datetime "confirmed_at"
    t.datetime "resolution_applied_at"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_by_id"], name: "index_incidents_on_confirmed_by_id"
    t.index ["detected_by_run_id"], name: "index_incidents_on_detected_by_run_id"
    t.index ["status"], name: "index_incidents_on_status"
    t.check_constraint "confidence IS NULL OR confidence >= 0::numeric AND confidence <= 1::numeric", name: "incidents_confidence_check"
    t.check_constraint "severity::text = ANY (ARRAY['low'::character varying::text, 'medium'::character varying::text, 'high'::character varying::text, 'critical'::character varying::text])", name: "incidents_severity_check"
    t.check_constraint "status::text = ANY (ARRAY['proposed'::character varying::text, 'confirmed'::character varying::text, 'resolved'::character varying::text, 'dismissed'::character varying::text])", name: "incidents_status_check"
  end

  create_table "knowledge_articles", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "body", null: false
    t.string "product"
    t.string "category"
    t.string "tags", default: [], null: false, array: true
    t.string "status", default: "draft", null: false
    t.string "source", default: "manual", null: false
    t.bigint "author_id"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_knowledge_articles_on_author_id"
    t.index ["slug"], name: "index_knowledge_articles_on_slug", unique: true
    t.index ["status"], name: "index_knowledge_articles_on_status"
    t.index ["tags"], name: "index_knowledge_articles_on_tags", using: :gin
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'published'::character varying::text])", name: "knowledge_articles_status_check"
  end

  create_table "macros", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.jsonb "actions", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_macros_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_seen_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sla_policies", force: :cascade do |t|
    t.string "name", null: false
    t.integer "first_reply_minutes", null: false
    t.integer "resolution_minutes", null: false
    t.string "priority"
    t.string "channel"
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_sla_policies_on_position"
    t.check_constraint "channel IS NULL OR (channel::text = ANY (ARRAY['email'::character varying::text, 'web'::character varying::text, 'chat'::character varying::text]))", name: "sla_policies_channel_check"
    t.check_constraint "first_reply_minutes > 0 AND resolution_minutes > 0", name: "sla_policies_minutes_check"
    t.check_constraint "priority IS NULL OR (priority::text = ANY (ARRAY['low'::character varying::text, 'normal'::character varying::text, 'high'::character varying::text, 'urgent'::character varying::text]))", name: "sla_policies_priority_check"
  end

  create_table "ticket_articles", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "knowledge_article_id", null: false
    t.bigint "linked_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["knowledge_article_id"], name: "index_ticket_articles_on_knowledge_article_id"
    t.index ["linked_by_id"], name: "index_ticket_articles_on_linked_by_id"
    t.index ["ticket_id", "knowledge_article_id"], name: "index_ticket_articles_on_ticket_id_and_knowledge_article_id", unique: true
    t.index ["ticket_id"], name: "index_ticket_articles_on_ticket_id"
  end

  create_table "ticket_links", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "related_ticket_id", null: false
    t.string "kind", default: "related", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["related_ticket_id"], name: "index_ticket_links_on_related_ticket_id"
    t.index ["ticket_id", "related_ticket_id"], name: "index_ticket_links_on_ticket_id_and_related_ticket_id", unique: true
    t.index ["ticket_id"], name: "index_ticket_links_on_ticket_id"
    t.check_constraint "kind::text = ANY (ARRAY['related'::character varying::text, 'merged'::character varying::text])", name: "ticket_links_kind_check"
    t.check_constraint "ticket_id <> related_ticket_id", name: "ticket_links_not_self_check"
  end

  create_table "ticket_messages", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "user_id"
    t.string "author_type", null: false
    t.text "body", null: false
    t.boolean "internal", default: false, null: false
    t.string "origin", default: "manual", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id", "created_at"], name: "index_ticket_messages_on_ticket_id_and_created_at"
    t.index ["ticket_id"], name: "index_ticket_messages_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_messages_on_user_id"
    t.check_constraint "author_type::text <> 'customer'::text OR internal = false", name: "ticket_messages_customer_public_check"
    t.check_constraint "author_type::text = ANY (ARRAY['agent'::character varying::text, 'customer'::character varying::text, 'system'::character varying::text])", name: "ticket_messages_author_type_check"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "number"
    t.string "subject", null: false
    t.text "description", null: false
    t.bigint "customer_id", null: false
    t.bigint "assignee_id"
    t.bigint "created_by_id"
    t.string "channel", null: false
    t.string "status", default: "open", null: false
    t.string "priority", default: "normal", null: false
    t.string "category"
    t.string "product"
    t.string "external_ref"
    t.datetime "first_response_at"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "sla_policy_id"
    t.bigint "merged_into_id"
    t.datetime "first_response_due_at"
    t.datetime "resolution_due_at"
    t.datetime "sla_breached_at"
    t.string "tags", default: [], null: false, array: true
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["category"], name: "index_tickets_on_category"
    t.index ["channel"], name: "index_tickets_on_channel"
    t.index ["created_at"], name: "index_tickets_on_created_at"
    t.index ["created_by_id"], name: "index_tickets_on_created_by_id"
    t.index ["customer_id"], name: "index_tickets_on_customer_id"
    t.index ["external_ref"], name: "index_tickets_on_external_ref", unique: true
    t.index ["merged_into_id"], name: "index_tickets_on_merged_into_id"
    t.index ["number"], name: "index_tickets_on_number", unique: true
    t.index ["priority"], name: "index_tickets_on_priority"
    t.index ["product"], name: "index_tickets_on_product"
    t.index ["sla_policy_id"], name: "index_tickets_on_sla_policy_id"
    t.index ["status"], name: "index_tickets_on_status"
    t.index ["tags"], name: "index_tickets_on_tags", using: :gin
    t.check_constraint "(status::text = 'resolved'::text) = (resolved_at IS NOT NULL)", name: "tickets_resolved_at_check"
    t.check_constraint "channel::text = ANY (ARRAY['email'::character varying::text, 'web'::character varying::text, 'chat'::character varying::text])", name: "tickets_channel_check"
    t.check_constraint "priority::text = ANY (ARRAY['low'::character varying::text, 'normal'::character varying::text, 'high'::character varying::text, 'urgent'::character varying::text])", name: "tickets_priority_check"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying::text, 'in_progress'::character varying::text, 'pending'::character varying::text, 'resolved'::character varying::text])", name: "tickets_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "agent", null: false
    t.string "team", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['manager'::character varying::text, 'agent'::character varying::text])", name: "users_role_check"
  end

  add_foreign_key "agent_runs", "users", column: "applied_by_id", on_delete: :nullify
  add_foreign_key "agent_runs", "users", on_delete: :nullify
  add_foreign_key "audit_logs", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "csat_ratings", "customers"
  add_foreign_key "csat_ratings", "tickets", on_delete: :cascade
  add_foreign_key "incident_tickets", "incidents", on_delete: :cascade
  add_foreign_key "incident_tickets", "tickets", on_delete: :cascade
  add_foreign_key "incidents", "agent_runs", column: "detected_by_run_id", on_delete: :nullify
  add_foreign_key "incidents", "users", column: "confirmed_by_id", on_delete: :nullify
  add_foreign_key "knowledge_articles", "users", column: "author_id", on_delete: :nullify
  add_foreign_key "sessions", "users", on_delete: :cascade
  add_foreign_key "ticket_articles", "knowledge_articles", on_delete: :cascade
  add_foreign_key "ticket_articles", "tickets", on_delete: :cascade
  add_foreign_key "ticket_articles", "users", column: "linked_by_id", on_delete: :nullify
  add_foreign_key "ticket_links", "tickets", column: "related_ticket_id", on_delete: :cascade
  add_foreign_key "ticket_links", "tickets", on_delete: :cascade
  add_foreign_key "ticket_messages", "tickets", on_delete: :cascade
  add_foreign_key "ticket_messages", "users", on_delete: :nullify
  add_foreign_key "tickets", "customers"
  add_foreign_key "tickets", "sla_policies", on_delete: :nullify
  add_foreign_key "tickets", "tickets", column: "merged_into_id", on_delete: :nullify
  add_foreign_key "tickets", "users", column: "assignee_id", on_delete: :nullify
  add_foreign_key "tickets", "users", column: "created_by_id", on_delete: :nullify
end
