# == Schema Information
#
# Table name: vibeexe_crm_lead_activities
#
#  id              :bigint           not null, primary key
#  activity_type   :string           not null
#  metadata        :jsonb            not null
#  occurred_at     :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint
#  lead_id         :bigint
#  user_id         :bigint
#
# Indexes
#
#  index_vibeexe_crm_lead_activities_on_account_id       (account_id)
#  index_vibeexe_crm_lead_activities_on_conversation_id  (conversation_id)
#  index_vibeexe_crm_lead_activities_on_lead_id          (lead_id)
#  index_vibeexe_crm_lead_activities_on_user_id          (user_id)
#  index_vibeexe_lead_activities_on_conversation_lookup  (account_id,conversation_id)
#  index_vibeexe_lead_activities_on_lead_lookup          (account_id,lead_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (lead_id => vibeexe_crm_leads.id)
#  fk_rails_...  (user_id => users.id)
#
class VibeExe::Crm::LeadActivity < ApplicationRecord
  self.table_name = 'vibeexe_crm_lead_activities'

  belongs_to :account
  belongs_to :lead, class_name: 'VibeExe::Crm::Lead', optional: true
  belongs_to :conversation, optional: true
  belongs_to :user, optional: true

  validates :activity_type, :occurred_at, presence: true
  validate :validate_account_consistency

  before_validation :set_occurred_at

  private

  def set_occurred_at
    self.occurred_at ||= Time.zone.now
  end

  def validate_account_consistency
    errors.add(:lead, :invalid) if lead.present? && lead.account_id != account_id
    errors.add(:conversation, :invalid) if conversation.present? && conversation.account_id != account_id
    errors.add(:user, :invalid) if user.present? && user.account_users.where(account_id: account_id).blank?
  end
end
