class VibeExe::Crm::DeleteLeadNoteService
  def initialize(note:, user:)
    @note = note
    @user = user
  end

  def perform
    VibeExe::Crm::LeadNote.transaction do
      lead = @note.lead
      metadata = { note_id: @note.id, body_excerpt: @note.body.truncate(160) }
      @note.destroy!
      lead.activities.create!(account: lead.account, user: @user, activity_type: 'note_deleted', metadata: metadata)
      lead.update_column(:last_activity_at, Time.current)
    end
  end
end
