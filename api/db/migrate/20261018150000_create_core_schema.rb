class CreateCoreSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "agent"
      t.string :team, null: false
      t.string :title
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
    add_check_constraint :users, "role IN ('manager','agent')", name: "users_role_check"

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :last_seen_at
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end
    add_index :sessions, :token_digest, unique: true

    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :company
      t.string :tier, null: false, default: "standard"
      t.string :city
      t.timestamps
    end
    add_index :customers, "lower(email)", unique: true, name: "index_customers_on_lower_email"
    add_check_constraint :customers, "tier IN ('standard','pro','enterprise')", name: "customers_tier_check"

    create_table :tickets do |t|
      t.string :number
      t.string :subject, null: false
      t.text :description, null: false
      t.references :customer, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :channel, null: false
      t.string :status, null: false, default: "open"
      t.string :priority, null: false, default: "normal"
      t.string :category
      t.string :product
      t.string :external_ref
      t.datetime :first_response_at
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :tickets, :number, unique: true
    add_index :tickets, :external_ref, unique: true
    add_index :tickets, :status
    add_index :tickets, :priority
    add_index :tickets, :channel
    add_index :tickets, :category
    add_index :tickets, :product
    add_index :tickets, :created_at
    add_check_constraint :tickets, "channel IN ('email','web','chat')", name: "tickets_channel_check"
    add_check_constraint :tickets, "status IN ('open','in_progress','pending','resolved')", name: "tickets_status_check"
    add_check_constraint :tickets, "priority IN ('low','normal','high','urgent')", name: "tickets_priority_check"
    add_check_constraint :tickets, "(status = 'resolved') = (resolved_at IS NOT NULL)", name: "tickets_resolved_at_check"

    create_table :ticket_messages do |t|
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :author_type, null: false
      t.text :body, null: false
      t.boolean :internal, null: false, default: false
      t.string :origin, null: false, default: "manual"
      t.timestamps
    end
    add_index :ticket_messages, [ :ticket_id, :created_at ]
    add_check_constraint :ticket_messages, "author_type IN ('agent','customer','system')", name: "ticket_messages_author_type_check"
    add_check_constraint :ticket_messages, "author_type <> 'customer' OR internal = false", name: "ticket_messages_customer_public_check"

    create_table :knowledge_articles do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :body, null: false
      t.string :product
      t.string :category
      t.string :tags, array: true, null: false, default: []
      t.string :status, null: false, default: "draft"
      t.string :source, null: false, default: "manual"
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :published_at
      t.timestamps
    end
    add_index :knowledge_articles, :slug, unique: true
    add_index :knowledge_articles, :status
    add_index :knowledge_articles, :tags, using: :gin
    add_check_constraint :knowledge_articles, "status IN ('draft','published')", name: "knowledge_articles_status_check"

    create_table :ticket_articles do |t|
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.references :knowledge_article, null: false, foreign_key: { on_delete: :cascade }
      t.references :linked_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :ticket_articles, [ :ticket_id, :knowledge_article_id ], unique: true

    create_table :agent_runs do |t|
      t.string :agent_type, null: false
      t.string :status, null: false
      t.string :source, null: false
      t.string :model
      t.references :subject, polymorphic: true
      t.references :user, foreign_key: { on_delete: :nullify }
      t.integer :tokens_in, null: false, default: 0
      t.integer :tokens_out, null: false, default: 0
      t.integer :latency_ms
      t.decimal :cost_usd, precision: 12, scale: 8, null: false, default: 0
      t.jsonb :output, null: false, default: {}
      t.string :error_summary
      t.string :provider_request_id
      t.datetime :applied_at
      t.references :applied_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :agent_runs, [ :agent_type, :created_at ]
    add_check_constraint :agent_runs, "status IN ('succeeded','failed')", name: "agent_runs_status_check"
    add_check_constraint :agent_runs, "source IN ('openai','fallback','fake','none')", name: "agent_runs_source_check"

    create_table :incidents do |t|
      t.string :title, null: false
      t.text :summary, null: false
      t.text :suspected_root_cause
      t.string :severity, null: false, default: "medium"
      t.string :status, null: false, default: "proposed"
      t.decimal :confidence, precision: 4, scale: 3
      t.text :uncertainty
      t.string :product
      t.jsonb :symptoms, null: false, default: []
      t.jsonb :evidence, null: false, default: []
      t.jsonb :suggested_actions, null: false, default: []
      t.jsonb :resolution_plan, null: false, default: {}
      t.text :recommended_next_action
      t.text :resolution_note
      t.references :detected_by_run, foreign_key: { to_table: :agent_runs, on_delete: :nullify }
      t.references :confirmed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :confirmed_at
      t.datetime :resolution_applied_at
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :incidents, :status
    add_check_constraint :incidents, "status IN ('proposed','confirmed','resolved','dismissed')", name: "incidents_status_check"
    add_check_constraint :incidents, "severity IN ('low','medium','high','critical')", name: "incidents_severity_check"
    add_check_constraint :incidents, "confidence IS NULL OR (confidence >= 0 AND confidence <= 1)", name: "incidents_confidence_check"

    create_table :incident_tickets do |t|
      t.references :incident, null: false, foreign_key: { on_delete: :cascade }
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :similarity, precision: 4, scale: 3
      t.timestamps
    end
    add_index :incident_tickets, [ :incident_id, :ticket_id ], unique: true

    create_table :audit_logs do |t|
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :audit_logs, [ :target_type, :target_id ]
    add_index :audit_logs, :created_at
  end
end
