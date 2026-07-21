class Api::V1::Accounts::VibeExe::Crm::PipelinesController < Api::V1::Accounts::VibeExe::Crm::BaseController
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  def index
    authorize VibeExe::Crm::Lead

    pipelines = VibeExe::Crm::Pipeline.where(account: Current.account).ordered.includes(:stages)
    pipelines = pipelines.active unless params[:include_inactive].to_s == 'true'
    render json: pipelines.map { |pipeline| pipeline_payload(pipeline, include_inactive_stages: params[:include_inactive].to_s == 'true') }
  end

  def create
    authorize VibeExe::Crm::Pipeline

    pipeline = VibeExe::Crm::Pipeline.create!(pipeline_params.merge(account: Current.account))
    render json: { pipeline: pipeline_payload(pipeline, include_inactive_stages: true) }, status: :created
  end

  def update
    pipeline = VibeExe::Crm::Pipeline.find_by!(account: Current.account, id: params[:id])
    authorize pipeline

    VibeExe::Crm::Pipeline.transaction do
      if pipeline_params[:default].to_s == 'true'
        VibeExe::Crm::Pipeline.where(account: Current.account).where.not(id: pipeline.id).update_all(default: false)
      end
      pipeline.update!(pipeline_params)
    end

    render json: { pipeline: pipeline_payload(pipeline, include_inactive_stages: true) }
  end

  def destroy
    pipeline = VibeExe::Crm::Pipeline.find_by!(account: Current.account, id: params[:id])
    authorize pipeline

    if pipeline.leads.exists? || VibeExe::Crm::InboxLeadConfig.exists?(account: Current.account, default_pipeline: pipeline)
      return render json: { error: 'Pipeline is used by leads or inbox defaults' }, status: :unprocessable_entity
    end

    pipeline.destroy!
    head :ok
  end

  def bootstrap_default
    authorize VibeExe::Crm::Pipeline, :create?

    pipeline = VibeExe::Crm::BootstrapDefaultPipelineService.new(account: Current.account).perform
    render json: { pipeline: pipeline_payload(pipeline, include_inactive_stages: true) }
  end

  private

  def pipeline_params
    params.permit(:name, :active, :default, :position)
  end
end
