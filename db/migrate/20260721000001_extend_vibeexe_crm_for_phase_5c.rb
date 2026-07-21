class ExtendVibeexeCrmForPhase5c < ActiveRecord::Migration[7.0]
  def change
    change_table :vibeexe_crm_pipeline_stages, bulk: true do |t|
      t.integer :stage_type, null: false, default: 0
      t.integer :probability, null: false, default: 0
    end

    change_table :vibeexe_crm_leads, bulk: true do |t|
      t.decimal :estimated_value, precision: 15, scale: 2
      t.string :currency, null: false, default: 'USD'
      t.date :expected_close_date
      t.datetime :last_activity_at
    end

    change_table :vibeexe_crm_inbox_lead_configs, bulk: true do |t|
      t.references :default_stage, foreign_key: { to_table: :vibeexe_crm_pipeline_stages }
    end

    add_index :vibeexe_crm_leads, [:account_id, :status, :archived_at], name: 'index_vibeexe_leads_on_status_lookup'
    add_index :vibeexe_crm_leads, [:account_id, :expected_close_date], name: 'index_vibeexe_leads_on_expected_close_lookup'
    add_index :vibeexe_crm_leads, [:account_id, :last_activity_at], name: 'index_vibeexe_leads_on_last_activity_lookup'
  end
end
