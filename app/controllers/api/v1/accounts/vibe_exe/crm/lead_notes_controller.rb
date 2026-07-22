class Api::V1::Accounts::VibeExe::Crm::LeadNotesController < Api::V1::Accounts::VibeExe::Crm::BaseController
  RESULTS_PER_PAGE = 25

  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  before_action :set_lead
  before_action :set_note, only: [:update, :destroy, :destroy_attachment]

  def index
    authorize VibeExe::Crm::LeadNote
    notes = @lead.notes.includes(:author).with_attached_files.chronological.page(current_page).per(RESULTS_PER_PAGE)

    render json: { notes: notes.map { |note| note_payload(note) }, meta: pagination_payload(notes) }
  end

  def create
    authorize VibeExe::Crm::LeadNote
    note = VibeExe::Crm::CreateLeadNoteService.new(
      lead: @lead,
      user: Current.user,
      body: params.require(:body),
      blob_ids: params[:blob_ids] || []
    ).perform

    render json: { note: note_payload(note) }, status: :created
  end

  def update
    authorize @note
    note = VibeExe::Crm::UpdateLeadNoteService.new(
      note: @note,
      user: Current.user,
      body: params.require(:body),
      blob_ids: params[:blob_ids] || []
    ).perform

    render json: { note: note_payload(note) }
  end

  def destroy
    authorize @note
    VibeExe::Crm::DeleteLeadNoteService.new(note: @note, user: Current.user).perform
    head :no_content
  end

  def destroy_attachment
    authorize @note, :update?
    @note.files.attachments.find(params[:attachment_id]).purge
    head :no_content
  end

  private

  def set_lead
    @lead = VibeExe::Crm::Lead.find_by!(account: Current.account, id: params[:lead_id])
    authorize @lead, :show?
  end

  def set_note
    @note = @lead.notes.find(params[:id])
  end

  def note_payload(note)
    {
      id: note.id,
      body: note.body,
      author: user_payload(note.author),
      edited_at: note.edited_at,
      created_at: note.created_at,
      updated_at: note.updated_at,
      attachments: note.files.map { |file| attachment_payload(file) },
      can_edit: policy(note).update?,
      can_delete: policy(note).destroy?
    }
  end

  def attachment_payload(file)
    {
      id: file.id,
      filename: file.filename.to_s,
      content_type: file.content_type,
      byte_size: file.byte_size,
      file_url: url_for(file)
    }
  end

  def current_page
    (params[:page].presence || 1).to_i
  end

  def pagination_payload(notes)
    { current_page: current_page, total_count: notes.total_count, per_page: RESULTS_PER_PAGE }
  end
end
