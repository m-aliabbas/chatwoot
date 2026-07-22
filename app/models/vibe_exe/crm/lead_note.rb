# == Schema Information
#
# Table name: vibeexe_crm_lead_notes
#
#  id         :bigint           not null, primary key
#  body       :text             not null
#  edited_at  :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  author_id  :bigint           not null
#  lead_id    :bigint           not null
#
# Indexes
#
#  index_vibeexe_crm_lead_notes_on_account_id  (account_id)
#  index_vibeexe_crm_lead_notes_on_author_id   (author_id)
#  index_vibeexe_crm_lead_notes_on_lead_id     (lead_id)
#  index_vibeexe_lead_notes_on_lead_timeline   (account_id,lead_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (lead_id => vibeexe_crm_leads.id)
#
class VibeExe::Crm::LeadNote < ApplicationRecord
  self.table_name = 'vibeexe_crm_lead_notes'

  MAX_BODY_LENGTH = 10_000

  belongs_to :account
  belongs_to :lead, class_name: 'VibeExe::Crm::Lead'
  belongs_to :author, class_name: 'User'
  has_many_attached :files

  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }
  validate :validate_account_consistency
  validate :validate_files

  scope :chronological, -> { order(created_at: :desc, id: :desc) }

  private

  def validate_account_consistency
    errors.add(:lead, :invalid) if lead.present? && lead.account_id != account_id
    errors.add(:author, :invalid) if author.present? && author.account_users.where(account_id: account_id).blank?
  end

  def validate_files
    maximum_size = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', 40).to_i
    maximum_size = 40 if maximum_size <= 0
    files.each do |file|
      errors.add(:files, :too_large, filename: file.filename, maximum_size: maximum_size) if file.byte_size > maximum_size.megabytes
    end
  end
end
