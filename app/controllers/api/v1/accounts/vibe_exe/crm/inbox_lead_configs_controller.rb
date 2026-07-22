class Api::V1::Accounts::VibeExe::Crm::InboxLeadConfigsController < Api::V1::Accounts::VibeExe::Crm::BaseController
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  before_action :set_inbox
  before_action :set_config

  def show
    authorize @config

    render json: config_payload
  end

  def update
    authorize @config

    @config.update!(config_params)
    render json: config_payload
  end

  private

  def set_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def set_config
    @config = VibeExe::Crm::InboxLeadConfigResolver.new(inbox: @inbox).perform
  end

  def config_params
    params.permit(:lead_creation_mode, :default_pipeline_id, :default_stage_id, :default_owner_id, :default_team_id).tap do |permitted|
      %i[default_pipeline_id default_stage_id default_owner_id default_team_id].each do |key|
        permitted[key] = nil if permitted[key].blank?
      end
    end
  end

  def config_payload
    {
      id: @config.id,
      inbox_id: @inbox.id,
      lead_creation_mode: @config.lead_creation_mode,
      default_pipeline_id: @config.default_pipeline_id,
      default_stage_id: @config.default_stage_id,
      default_owner_id: @config.default_owner_id,
      default_team_id: @config.default_team_id
    }
  end
end
