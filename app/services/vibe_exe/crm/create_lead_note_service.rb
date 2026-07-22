class VibeExe::Crm::CreateLeadNoteService
  def initialize(lead:, user:, body:, blob_ids: [])
    @lead = lead
    @user = user
    @body = body
    @blob_ids = blob_ids
  end

  def perform
    VibeExe::Crm::LeadNote.transaction do
      note = @lead.notes.new(account: @lead.account, author: @user, body: @body)
      @blob_ids.each { |blob_id| note.files.attach(ActiveStorage::Blob.find_signed!(blob_id)) }
      note.save!
      record_activity!('note_created', note)
      note
    end
  end

  private

  def record_activity!(activity_type, note)
    @lead.activities.create!(
      account: @lead.account,
      user: @user,
      activity_type: activity_type,
      metadata: { note_id: note.id, body_excerpt: note.body.truncate(160) }
    )
    @lead.update_column(:last_activity_at, Time.current)
  end
end
