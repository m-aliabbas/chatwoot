# == Schema Information
#
# Table name: vibeexe_crm_tasks
#
#  id               :bigint           not null, primary key
#  cancelled_at     :datetime
#  completed_at     :datetime
#  completion_note  :text
#  description      :text
#  due_at           :datetime         not null
#  priority         :integer          default("medium"), not null
#  reminder_at      :datetime
#  reminder_sent_at :datetime
#  status           :integer          default("pending"), not null
#  task_type        :integer          default("general"), not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  assignee_id      :bigint
#  completer_id     :bigint
#  conversation_id  :bigint
#  creator_id       :bigint           not null
#  lead_id          :bigint           not null
#
# Indexes
#
#  index_vibeexe_crm_tasks_on_account_id       (account_id)
#  index_vibeexe_crm_tasks_on_assignee_id      (assignee_id)
#  index_vibeexe_crm_tasks_on_completer_id     (completer_id)
#  index_vibeexe_crm_tasks_on_conversation_id  (conversation_id)
#  index_vibeexe_crm_tasks_on_creator_id       (creator_id)
#  index_vibeexe_crm_tasks_on_lead_id          (lead_id)
#  index_vibeexe_tasks_on_account_status_due   (account_id,status,due_at)
#  index_vibeexe_tasks_on_assignee_worklist    (account_id,assignee_id,status,due_at)
#  index_vibeexe_tasks_on_due_reminders        (account_id,status,reminder_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (completer_id => users.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (lead_id => vibeexe_crm_leads.id)
#
class VibeExe::Crm::Task < ApplicationRecord
  self.table_name = 'vibeexe_crm_tasks'

  MAX_TITLE_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 10_000
  MAX_COMPLETION_NOTE_LENGTH = 5_000

  belongs_to :account
  belongs_to :lead, class_name: 'VibeExe::Crm::Lead'
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :creator, class_name: 'User'
  belongs_to :completer, class_name: 'User', optional: true
  belongs_to :conversation, optional: true
  has_many_attached :files

  enum task_type: { follow_up: 0, call: 1, meeting: 2, whatsapp: 3, email: 4, general: 5, other: 6 }
  enum status: { pending: 0, completed: 1, cancelled: 2 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  validates :title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH }
  validates :completion_note, length: { maximum: MAX_COMPLETION_NOTE_LENGTH }
  validates :due_at, presence: true
  validate :validate_account_consistency
  validate :validate_reminder_time
  validate :validate_lifecycle_timestamps
  validate :validate_files

  scope :overdue, -> { pending.where('due_at < ?', Time.current) }
  scope :due_today, -> { pending.where(due_at: Time.zone.now.all_day) }
  scope :upcoming, -> { pending.where('due_at >= ?', Time.current) }
  scope :reminders_due, -> { pending.where(reminder_sent_at: nil).where('reminder_at <= ?', Time.current) }
  scope :worklist_order, -> { order(Arel.sql('CASE WHEN due_at < CURRENT_TIMESTAMP THEN 0 ELSE 1 END ASC'), due_at: :asc, id: :asc) }

  def overdue?
    pending? && due_at < Time.current
  end

  def snapshot
    {
      task_type: task_type,
      priority: priority,
      assignee_id: assignee_id,
      due_at: due_at,
      reminder_at: reminder_at
    }
  end

  private

  def validate_account_consistency
    errors.add(:lead, :invalid) if lead.present? && lead.account_id != account_id
    errors.add(:assignee, :invalid) if assignee.present? && !account_member?(assignee)
    errors.add(:creator, :invalid) if creator.present? && !account_member?(creator)
    errors.add(:completer, :invalid) if completer.present? && !account_member?(completer)
    errors.add(:conversation, :invalid) if conversation.present? && conversation.account_id != account_id
    errors.add(:conversation, :invalid) if conversation.present? && lead.present? && conversation.contact_id != lead.contact_id
  end

  def validate_reminder_time
    errors.add(:reminder_at, :after_due_at) if reminder_at.present? && due_at.present? && reminder_at > due_at
  end

  def validate_lifecycle_timestamps
    errors.add(:completed_at, :invalid) if completed_at.present? != completed?
    errors.add(:completer, :invalid) if completer.present? != completed?
    errors.add(:cancelled_at, :invalid) if cancelled_at.present? != cancelled?
  end

  def account_member?(user)
    user.account_users.where(account_id: account_id).exists?
  end

  def validate_files
    maximum_size = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', 40).to_i
    maximum_size = 40 if maximum_size <= 0
    files.each do |file|
      errors.add(:files, :too_large, filename: file.filename, maximum_size: maximum_size) if file.byte_size > maximum_size.megabytes
    end
  end
end
