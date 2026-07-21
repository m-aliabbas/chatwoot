class Api::V1::Accounts::VibeExe::Crm::LeadActivitiesController < Api::V1::Accounts::VibeExe::Crm::BaseController
  RESULTS_PER_PAGE = 25

  before_action :set_lead

  def index
    authorize @lead

    activities = @lead.activities.includes(:user, :conversation).order(occurred_at: :desc, id: :desc).page(current_page).per(RESULTS_PER_PAGE)
    render json: {
      activities: activities.map { |activity| activity_payload(activity) },
      meta: {
        current_page: current_page,
        total_count: @lead.activities.count,
        per_page: RESULTS_PER_PAGE
      }
    }
  end

  def create
    authorize @lead, :update?

    activity = VibeExe::Crm::LeadActivity.create!(
      account: Current.account,
      lead: @lead,
      user: Current.user,
      activity_type: 'note_added',
      metadata: { body: params.require(:body) }
    )
    @lead.update_column(:last_activity_at, Time.zone.now)
    render json: { activity: activity_payload(activity) }, status: :created
  end

  private

  def set_lead
    @lead = VibeExe::Crm::Lead.find_by!(account: Current.account, id: params[:lead_id])
  end

  def activity_payload(activity)
    {
      id: activity.id,
      activity_type: activity.activity_type,
      actor: user_payload(activity.user),
      conversation_id: activity.conversation&.display_id,
      metadata: activity.metadata,
      occurred_at: activity.occurred_at
    }
  end

  def current_page
    (params[:page].presence || 1).to_i
  end
end
