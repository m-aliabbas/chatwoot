# == Schema Information
#
# Table name: vibeexe_crm_leads
#
#  id                  :bigint           not null, primary key
#  archived_at         :datetime
#  closed_at           :datetime
#  closed_reason       :string
#  closed_status       :string
#  currency            :string           default("USD"), not null
#  estimated_value     :decimal(15, 2)
#  expected_close_date :date
#  last_activity_at    :datetime
#  metadata            :jsonb            not null
#  priority            :integer          default("medium"), not null
#  source              :string           not null
#  status              :integer          default("open"), not null
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  contact_id          :bigint           not null
#  created_by_id       :bigint
#  owner_id            :bigint
#  pipeline_id         :bigint           not null
#  pipeline_stage_id   :bigint           not null
#  team_id             :bigint
#
# Indexes
#
#  index_vibeexe_crm_leads_on_account_id         (account_id)
#  index_vibeexe_crm_leads_on_contact_id         (contact_id)
#  index_vibeexe_crm_leads_on_created_by_id      (created_by_id)
#  index_vibeexe_crm_leads_on_owner_id           (owner_id)
#  index_vibeexe_crm_leads_on_pipeline_id        (pipeline_id)
#  index_vibeexe_crm_leads_on_pipeline_stage_id  (pipeline_stage_id)
#  index_vibeexe_crm_leads_on_team_id            (team_id)
#  index_vibeexe_leads_on_expected_close_lookup  (account_id,expected_close_date)
#  index_vibeexe_leads_on_last_activity_lookup   (account_id,last_activity_at)
#  index_vibeexe_leads_on_open_contact_lookup    (account_id,contact_id,status,archived_at)
#  index_vibeexe_leads_on_pipeline_lookup        (account_id,pipeline_id,pipeline_stage_id)
#  index_vibeexe_leads_on_status_lookup          (account_id,status,archived_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (owner_id => users.id)
#  fk_rails_...  (pipeline_id => vibeexe_crm_pipelines.id)
#  fk_rails_...  (pipeline_stage_id => vibeexe_crm_pipeline_stages.id)
#  fk_rails_...  (team_id => teams.id)
#
class VibeExe::Crm::Lead < ApplicationRecord
  self.table_name = 'vibeexe_crm_leads'

  include Labelable

  belongs_to :account
  belongs_to :contact
  belongs_to :pipeline, class_name: 'VibeExe::Crm::Pipeline'
  belongs_to :pipeline_stage, class_name: 'VibeExe::Crm::PipelineStage'
  belongs_to :owner, class_name: 'User', optional: true
  belongs_to :team, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :lead_conversations, class_name: 'VibeExe::Crm::LeadConversation', dependent: :destroy
  has_many :conversations, through: :lead_conversations
  has_many :activities, class_name: 'VibeExe::Crm::LeadActivity', dependent: :destroy
  has_many :notes, class_name: 'VibeExe::Crm::LeadNote', dependent: :destroy
  has_many :tasks, class_name: 'VibeExe::Crm::Task', dependent: :destroy

  enum status: { open: 0, won: 1, lost: 2 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  validates :title, :source, presence: true
  validates :currency, presence: true
  validates :estimated_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :validate_account_consistency

  before_validation :set_last_activity_at, on: :create

  scope :available_for_contact, lambda { |account, contact|
    where(account: account, contact: contact, status: :open, archived_at: nil, closed_at: nil, closed_status: nil)
  }

  scope :active, -> { where(archived_at: nil) }

  private

  def validate_account_consistency
    errors.add(:contact, :invalid) if contact.present? && contact.account_id != account_id
    errors.add(:pipeline, :invalid) if pipeline.present? && pipeline.account_id != account_id
    errors.add(:pipeline, :invalid) if pipeline.present? && !pipeline.active?
    errors.add(:pipeline_stage, :invalid) if pipeline_stage.present? && pipeline_stage.account_id != account_id
    errors.add(:pipeline_stage, :invalid) if pipeline_stage.present? && pipeline.present? && pipeline_stage.pipeline_id != pipeline_id
    errors.add(:pipeline_stage, :invalid) if pipeline_stage.present? && !pipeline_stage.active?
    errors.add(:owner, :invalid) if owner.present? && owner.account_users.where(account_id: account_id).blank?
    errors.add(:team, :invalid) if team.present? && team.account_id != account_id
    errors.add(:created_by, :invalid) if created_by.present? && created_by.account_users.where(account_id: account_id).blank?
  end

  def set_last_activity_at
    self.last_activity_at ||= Time.zone.now
  end
end
