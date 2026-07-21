# == Schema Information
#
# Table name: vibeexe_crm_pipeline_stages
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  default     :boolean          default(FALSE), not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  pipeline_id :bigint           not null
#
# Indexes
#
#  index_vibeexe_crm_pipeline_stages_on_account_id               (account_id)
#  index_vibeexe_crm_pipeline_stages_on_pipeline_id              (pipeline_id)
#  index_vibeexe_crm_pipeline_stages_on_pipeline_id_and_default  (pipeline_id,default)
#  index_vibeexe_crm_pipeline_stages_on_pipeline_id_and_name     (pipeline_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (pipeline_id => vibeexe_crm_pipelines.id)
#
class VibeExe::Crm::PipelineStage < ApplicationRecord
  self.table_name = 'vibeexe_crm_pipeline_stages'

  belongs_to :account
  belongs_to :pipeline, class_name: 'VibeExe::Crm::Pipeline'
  has_many :leads, class_name: 'VibeExe::Crm::Lead', dependent: :restrict_with_exception

  enum stage_type: { open_stage: 0, won_stage: 1, lost_stage: 2 }

  validates :name, presence: true, uniqueness: { scope: :pipeline_id }
  validates :probability, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :validate_account_consistency

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(default: :desc, position: :asc, id: :asc) }

  private

  def validate_account_consistency
    errors.add(:pipeline, :invalid) if pipeline.present? && pipeline.account_id != account_id
  end
end
