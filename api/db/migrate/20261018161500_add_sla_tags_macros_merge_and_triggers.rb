class AddSlaTagsMacrosMergeAndTriggers < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_policies do |t|
      t.string :name, null: false
      t.integer :first_reply_minutes, null: false
      t.integer :resolution_minutes, null: false
      t.string :priority
      t.string :channel
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :sla_policies, :position
    add_check_constraint :sla_policies, "first_reply_minutes > 0 AND resolution_minutes > 0", name: "sla_policies_minutes_check"
    add_check_constraint :sla_policies,
      "priority IS NULL OR priority IN ('low','normal','high','urgent')",
      name: "sla_policies_priority_check"
    add_check_constraint :sla_policies,
      "channel IS NULL OR channel IN ('email','web','chat')",
      name: "sla_policies_channel_check"

    create_table :macros do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :actions, null: false, default: {}
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :macros, :name, unique: true

    create_table :automation_rules do |t|
      t.string :name, null: false
      t.string :event, null: false
      t.jsonb :conditions, null: false, default: {}
      t.jsonb :actions, null: false, default: {}
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :automation_rules, [ :event, :position ]
    add_check_constraint :automation_rules,
      "event IN ('ticket_created','ticket_updated')",
      name: "automation_rules_event_check"

    create_table :ticket_links do |t|
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.references :related_ticket, null: false, foreign_key: { to_table: :tickets, on_delete: :cascade }
      t.string :kind, null: false, default: "related"
      t.timestamps
    end
    add_index :ticket_links, [ :ticket_id, :related_ticket_id ], unique: true
    add_check_constraint :ticket_links, "ticket_id <> related_ticket_id", name: "ticket_links_not_self_check"
    add_check_constraint :ticket_links, "kind IN ('related','merged')", name: "ticket_links_kind_check"

    add_reference :tickets, :sla_policy, foreign_key: { on_delete: :nullify }
    add_reference :tickets, :merged_into, foreign_key: { to_table: :tickets, on_delete: :nullify }
    add_column :tickets, :first_response_due_at, :datetime
    add_column :tickets, :resolution_due_at, :datetime
    add_column :tickets, :sla_breached_at, :datetime
    add_column :tickets, :tags, :string, array: true, null: false, default: []
    add_index :tickets, :tags, using: :gin
  end
end
