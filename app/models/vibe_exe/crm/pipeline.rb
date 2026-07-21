# == Schema Information
#
# Table name: vibeexe_crm_pipelines
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE), not null
#  default    :boolean          default(FALSE), not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_vibeexe_crm_pipelines_on_account_id              (account_id)
#  index_vibeexe_crm_pipelines_on_account_id_and_default  (account_id,default)
#  index_vibeexe_crm_pipelines_on_account_id_and_name     (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class VibeExe::Crm::Pipeline < ApplicationRecord
  self.table_name = 'vibeexe_crm_pipelines'

  belongs_to :account
  has_many :stages, class_name: 'VibeExe::Crm::PipelineStage', dependent: :destroy
  has_many :leads, class_name: 'VibeExe::Crm::Lead', dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :account_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(default: :desc, position: :asc, id: :asc) }

end
