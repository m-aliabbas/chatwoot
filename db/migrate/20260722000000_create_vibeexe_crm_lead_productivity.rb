class CreateVibeexeCrmLeadProductivity < ActiveRecord::Migration[7.0]
  def change
    create_table :vibeexe_crm_lead_notes do |t|
      t.references :account, null: false, foreign_key: true
      t.references :lead, null: false, foreign_key: { to_table: :vibeexe_crm_leads }
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.datetime :edited_at
      t.timestamps
    end

    add_index :vibeexe_crm_lead_notes, [:account_id, :lead_id, :created_at], name: 'index_vibeexe_lead_notes_on_lead_timeline'

    create_table :vibeexe_crm_tasks do |t|
      t.references :account, null: false, foreign_key: true
      t.references :lead, null: false, foreign_key: { to_table: :vibeexe_crm_leads }
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :completer, foreign_key: { to_table: :users }
      t.references :conversation, foreign_key: true
      t.integer :task_type, null: false, default: 5
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.datetime :due_at, null: false
      t.datetime :reminder_at
      t.datetime :reminder_sent_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.text :completion_note
      t.timestamps
    end

    add_index :vibeexe_crm_tasks, [:account_id, :status, :due_at], name: 'index_vibeexe_tasks_on_account_status_due'
    add_index :vibeexe_crm_tasks, [:account_id, :assignee_id, :status, :due_at], name: 'index_vibeexe_tasks_on_assignee_worklist'
    add_index :vibeexe_crm_tasks, [:account_id, :status, :reminder_at], name: 'index_vibeexe_tasks_on_due_reminders'
  end
end
