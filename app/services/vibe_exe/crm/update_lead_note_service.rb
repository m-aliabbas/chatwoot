class VibeExe::Crm::UpdateLeadNoteService
  def initialize(note:, user:, body:, blob_ids: [])
    @note = note
    @user = user
    @body = body
    @blob_ids = blob_ids
  end

  def perform
    VibeExe::Crm::LeadNote.transaction do
      @blob_ids.each { |blob_id| @note.files.attach(ActiveStorage::Blob.find_signed!(blob_id)) }
      @note.update!(body: @body, edited_at: Time.current)
      @note.lead.activities.create!(
        account: @note.account,
        user: @user,
        activity_type: 'note_updated',
        metadata: { note_id: @note.id, body_excerpt: @note.body.truncate(160), attachments_added: @blob_ids.length }
      )
      @note.lead.update_column(:last_activity_at, Time.current)
      @note
    end
  end
end
