# == Schema Information
#
# Table name: vibeexe_crm_inbox_lead_configs
#
#  id                  :bigint           not null, primary key
#  lead_creation_mode  :integer          default("manual"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  default_owner_id    :bigint
#  default_pipeline_id :bigint
#  default_stage_id    :bigint
#  default_team_id     :bigint
#  inbox_id            :bigint           not null
#
# Indexes
#
#  index_vibeexe_crm_inbox_lead_configs_on_account_id           (account_id)
#  index_vibeexe_crm_inbox_lead_configs_on_default_owner_id     (default_owner_id)
#  index_vibeexe_crm_inbox_lead_configs_on_default_pipeline_id  (default_pipeline_id)
#  index_vibeexe_crm_inbox_lead_configs_on_default_stage_id     (default_stage_id)
#  index_vibeexe_crm_inbox_lead_configs_on_default_team_id      (default_team_id)
#  index_vibeexe_crm_inbox_lead_configs_on_inbox_id             (inbox_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (default_owner_id => users.id)
#  fk_rails_...  (default_pipeline_id => vibeexe_crm_pipelines.id)
#  fk_rails_...  (default_stage_id => vibeexe_crm_pipeline_stages.id)
#  fk_rails_...  (default_team_id => teams.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class VibeExe::Crm::InboxLeadConfig < ApplicationRecord
  self.table_name = 'vibeexe_crm_inbox_lead_configs'

  belongs_to :account
  belongs_to :inbox
  belongs_to :default_pipeline, class_name: 'VibeExe::Crm::Pipeline', optional: true
  belongs_to :default_stage, class_name: 'VibeExe::Crm::PipelineStage', optional: true
  belongs_to :default_owner, class_name: 'User', optional: true
  belongs_to :default_team, class_name: 'Team', optional: true

  enum lead_creation_mode: { never: 0, manual: 1, automatic: 2 }

  validates :inbox_id, uniqueness: true
  validate :validate_account_consistency

  private

  def validate_account_consistency
    errors.add(:inbox, :invalid) if inbox.present? && inbox.account_id != account_id
    errors.add(:default_pipeline, :invalid) if default_pipeline.present? && default_pipeline.account_id != account_id
    errors.add(:default_stage, :invalid) if default_stage.present? && default_stage.account_id != account_id
    errors.add(:default_stage, :invalid) if default_stage.present? && default_pipeline.present? && default_stage.pipeline_id != default_pipeline_id
    errors.add(:default_owner, :invalid) if default_owner.present? && default_owner.account_users.where(account_id: account_id).blank?
    errors.add(:default_team, :invalid) if default_team.present? && default_team.account_id != account_id
  end
end
