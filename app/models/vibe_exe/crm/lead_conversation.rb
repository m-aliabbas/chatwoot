# == Schema Information
#
# Table name: vibeexe_crm_lead_conversations
#
#  id              :bigint           not null, primary key
#  source          :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  lead_id         :bigint           not null
#  linked_by_id    :bigint
#
# Indexes
#
#  index_vibeexe_crm_lead_conversations_on_account_id         (account_id)
#  index_vibeexe_crm_lead_conversations_on_conversation_id    (conversation_id)
#  index_vibeexe_crm_lead_conversations_on_lead_id            (lead_id)
#  index_vibeexe_crm_lead_conversations_on_linked_by_id       (linked_by_id)
#  index_vibeexe_lead_conversations_on_conversation_lookup    (account_id,conversation_id)
#  index_vibeexe_lead_conversations_on_lead_and_conversation  (lead_id,conversation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (lead_id => vibeexe_crm_leads.id)
#  fk_rails_...  (linked_by_id => users.id)
#
class VibeExe::Crm::LeadConversation < ApplicationRecord
  self.table_name = 'vibeexe_crm_lead_conversations'

  belongs_to :account
  belongs_to :lead, class_name: 'VibeExe::Crm::Lead'
  belongs_to :conversation
  belongs_to :linked_by, class_name: 'User', optional: true

  validates :source, presence: true
  validates :conversation_id, uniqueness: { scope: :lead_id }
  validate :validate_account_consistency

  private

  def validate_account_consistency
    errors.add(:lead, :invalid) if lead.present? && lead.account_id != account_id
    errors.add(:conversation, :invalid) if conversation.present? && conversation.account_id != account_id
    errors.add(:linked_by, :invalid) if linked_by.present? && linked_by.account_users.where(account_id: account_id).blank?
  end
end
