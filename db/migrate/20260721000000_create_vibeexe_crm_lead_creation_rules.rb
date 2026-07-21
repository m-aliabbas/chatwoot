class CreateVibeexeCrmLeadCreationRules < ActiveRecord::Migration[7.0]
  def change
    create_table :vibeexe_crm_pipelines do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.boolean :default, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :vibeexe_crm_pipelines, [:account_id, :name], unique: true
    add_index :vibeexe_crm_pipelines, [:account_id, :default]

    create_table :vibeexe_crm_pipeline_stages do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, null: false, foreign_key: { to_table: :vibeexe_crm_pipelines }
      t.string :name, null: false
      t.boolean :default, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :vibeexe_crm_pipeline_stages, [:pipeline_id, :name], unique: true
    add_index :vibeexe_crm_pipeline_stages, [:pipeline_id, :default]

    create_table :vibeexe_crm_leads do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :contact, null: false, foreign_key: true
      t.references :pipeline, null: false, foreign_key: { to_table: :vibeexe_crm_pipelines }
      t.references :pipeline_stage, null: false, foreign_key: { to_table: :vibeexe_crm_pipeline_stages }
      t.references :owner, foreign_key: { to_table: :users }
      t.references :team, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.string :source, null: false
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.datetime :archived_at
      t.datetime :closed_at
      t.string :closed_status
      t.string :closed_reason
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :vibeexe_crm_leads, [:account_id, :contact_id, :status, :archived_at], name: 'index_vibeexe_leads_on_open_contact_lookup'
    add_index :vibeexe_crm_leads, [:account_id, :pipeline_id, :pipeline_stage_id], name: 'index_vibeexe_leads_on_pipeline_lookup'

    create_table :vibeexe_crm_lead_conversations do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :lead, null: false, foreign_key: { to_table: :vibeexe_crm_leads }
      t.references :conversation, null: false, foreign_key: true
      t.references :linked_by, foreign_key: { to_table: :users }
      t.string :source, null: false
      t.timestamps
    end

    add_index :vibeexe_crm_lead_conversations, [:lead_id, :conversation_id],
              unique: true,
              name: 'index_vibeexe_lead_conversations_on_lead_and_conversation'
    add_index :vibeexe_crm_lead_conversations, [:account_id, :conversation_id], name: 'index_vibeexe_lead_conversations_on_conversation_lookup'

    create_table :vibeexe_crm_lead_activities do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :lead, foreign_key: { to_table: :vibeexe_crm_leads }
      t.references :conversation, foreign_key: true
      t.references :user, foreign_key: true
      t.string :activity_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :vibeexe_crm_lead_activities, [:account_id, :lead_id], name: 'index_vibeexe_lead_activities_on_lead_lookup'
    add_index :vibeexe_crm_lead_activities, [:account_id, :conversation_id], name: 'index_vibeexe_lead_activities_on_conversation_lookup'

    create_table :vibeexe_crm_inbox_lead_configs do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: false
      t.integer :lead_creation_mode, null: false, default: 1
      t.references :default_pipeline, foreign_key: { to_table: :vibeexe_crm_pipelines }
      t.references :default_owner, foreign_key: { to_table: :users }
      t.references :default_team, foreign_key: { to_table: :teams }
      t.timestamps
    end

    add_index :vibeexe_crm_inbox_lead_configs, :inbox_id, unique: true
  end
end
