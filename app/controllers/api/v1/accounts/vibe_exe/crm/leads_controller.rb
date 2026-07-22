class Api::V1::Accounts::VibeExe::Crm::LeadsController < Api::V1::Accounts::VibeExe::Crm::BaseController
  RESULTS_PER_PAGE = 25
  SORT_COLUMNS = {
    'title' => 'vibeexe_crm_leads.title',
    'created_at' => 'vibeexe_crm_leads.created_at',
    'updated_at' => 'vibeexe_crm_leads.updated_at',
    'last_activity_at' => 'vibeexe_crm_leads.last_activity_at',
    'expected_close_date' => 'vibeexe_crm_leads.expected_close_date',
    'estimated_value' => 'vibeexe_crm_leads.estimated_value'
  }.freeze

  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ArgumentError, with: :render_invalid_filter

  before_action :set_lead, only: [:show, :update, :archive, :restore, :mark_won, :mark_lost, :change_stage]

  def index
    authorize VibeExe::Crm::Lead

    leads = filtered_leads
    paginated_leads = leads.page(current_page).per(RESULTS_PER_PAGE)

    render json: {
      leads: paginated_leads.map { |lead| lead_summary(lead) },
      meta: {
        current_page: current_page,
        total_count: leads.count,
        per_page: RESULTS_PER_PAGE
      }
    }
  end

  def show
    authorize @lead

    render json: { lead: lead_detail_payload(@lead) }
  end

  def create
    authorize VibeExe::Crm::Lead

    lead = VibeExe::Crm::CreateLeadService.new(account: Current.account, user: Current.user, params: lead_params).perform
    render json: { lead: lead_detail_payload(lead) }, status: :created
  end

  def update
    authorize @lead

    lead = VibeExe::Crm::UpdateLeadService.new(lead: @lead, user: Current.user, params: lead_params).perform
    render json: { lead: lead_detail_payload(lead) }
  end

  def archive
    authorize @lead, :destroy?

    render json: { lead: lead_detail_payload(VibeExe::Crm::TransitionLeadService.new(lead: @lead, user: Current.user, params: {}).archive!) }
  end

  def restore
    authorize @lead, :update?

    render json: { lead: lead_detail_payload(VibeExe::Crm::TransitionLeadService.new(lead: @lead, user: Current.user, params: {}).restore!) }
  end

  def mark_won
    authorize @lead, :update?

    render json: { lead: lead_detail_payload(VibeExe::Crm::TransitionLeadService.new(lead: @lead, user: Current.user, params: {}).mark_won!) }
  end

  def mark_lost
    authorize @lead, :update?

    render json: {
      lead: lead_detail_payload(
        VibeExe::Crm::TransitionLeadService.new(lead: @lead, user: Current.user, params: params.permit(:closed_reason)).mark_lost!
      )
    }
  end

  def change_stage
    authorize @lead, :update?

    render json: {
      lead: lead_detail_payload(
        VibeExe::Crm::TransitionLeadService.new(lead: @lead, user: Current.user, params: params.permit(:pipeline_stage_id, :closed_reason)).change_stage!
      )
    }
  end

  def board
    authorize VibeExe::Crm::Lead, :index?

    pipeline = VibeExe::Crm::Pipeline.active.find_by!(account: Current.account, id: params.require(:pipeline_id))
    stages = pipeline.stages.active.ordered
    leads = filtered_leads.where(pipeline: pipeline).where(pipeline_stage: stages).limit(300)

    render json: {
      pipeline: pipeline_payload(pipeline),
      columns: stages.map do |stage|
        {
          stage: stage_payload(stage),
          leads: leads.select { |lead| lead.pipeline_stage_id == stage.id }.map { |lead| lead_summary(lead) }
        }
      end
    }
  end

  private

  def set_lead
    @lead = VibeExe::Crm::Lead
            .includes(:contact, :pipeline, :pipeline_stage, :owner, :team, :tags)
            .find_by!(account: Current.account, id: params[:id])
  end

  def filtered_leads
    scope = VibeExe::Crm::Lead
            .includes(:contact, :pipeline, :pipeline_stage, :owner, :team, :tags)
            .where(account: Current.account)
    scope = scope.active unless params[:include_archived].to_s == 'true'
    scope = scope.where(pipeline_id: params[:pipeline_id]) if params[:pipeline_id].present?
    scope = scope.where(pipeline_stage_id: params[:stage_id]) if params[:stage_id].present?
    scope = scope.where(owner_id: params[:owner_id]) if params[:owner_id].present?
    scope = scope.where(team_id: params[:team_id]) if params[:team_id].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.tagged_with(Current.account.labels.find(params[:label_id]).title, any: true) if params[:label_id].present?
    scope = scope.where('vibeexe_crm_leads.created_at >= ?', Time.zone.parse(params[:created_from]).beginning_of_day) if params[:created_from].present?
    scope = scope.where('vibeexe_crm_leads.created_at <= ?', Time.zone.parse(params[:created_to]).end_of_day) if params[:created_to].present?
    scope = scope.where('vibeexe_crm_leads.expected_close_date >= ?', Date.parse(params[:close_from])) if params[:close_from].present?
    scope = scope.where('vibeexe_crm_leads.expected_close_date <= ?', Date.parse(params[:close_to])) if params[:close_to].present?
    scope = apply_search(scope)
    scope.order(Arel.sql("#{sort_column} #{sort_direction}, vibeexe_crm_leads.id DESC"))
  end

  def apply_search(scope)
    return scope if params[:q].blank?

    query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
    scope.left_joins(:contact).where('vibeexe_crm_leads.title ILIKE :query OR contacts.name ILIKE :query OR contacts.email ILIKE :query', query: query)
  end

  def lead_params
    permitted = params.permit(
      :contact_id, :title, :pipeline_id, :pipeline_stage_id, :owner_id, :team_id, :source, :priority,
      :estimated_value, :currency, :expected_close_date, :closed_reason, metadata: {}
    )
    %i[owner_id team_id estimated_value expected_close_date closed_reason].each { |key| permitted[key] = nil if permitted[key].blank? }
    permitted
  end

  def current_page
    (params[:page].presence || 1).to_i
  end

  def sort_column
    SORT_COLUMNS[params[:sort_by].to_s] || SORT_COLUMNS['last_activity_at']
  end

  def sort_direction
    params[:sort_direction].to_s.downcase == 'asc' ? 'ASC' : 'DESC'
  end

  def render_invalid_filter(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
