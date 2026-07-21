class Api::V1::Accounts::VibeExe::Crm::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_crm_enabled

  private

  def ensure_crm_enabled
    return if Current.account.feature_enabled?('crm')

    render json: { error: 'CRM is not enabled for this account' }, status: :forbidden
  end

  def lead_summary(lead)
    {
      id: lead.id,
      title: lead.title,
      status: lead.status,
      source: lead.source,
      pipeline_id: lead.pipeline_id,
      pipeline_name: lead.pipeline.name,
      pipeline_stage_id: lead.pipeline_stage_id,
      pipeline_stage_name: lead.pipeline_stage.name,
      owner_id: lead.owner_id,
      team_id: lead.team_id,
      updated_at: lead.updated_at
    }
  end
end
