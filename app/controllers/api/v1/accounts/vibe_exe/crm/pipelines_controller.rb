class Api::V1::Accounts::VibeExe::Crm::PipelinesController < Api::V1::Accounts::VibeExe::Crm::BaseController
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  def index
    include_inactive = params[:include_inactive].to_s == 'true'
    include_inactive ? authorize(VibeExe::Crm::Pipeline) : authorize(VibeExe::Crm::Lead)

    pipelines = VibeExe::Crm::Pipeline.where(account: Current.account).ordered.includes(:stages)
    pipelines = pipelines.active unless include_inactive
    render json: pipelines.map { |pipeline| pipeline_payload(pipeline, include_inactive_stages: include_inactive) }
  end

  def create
    authorize VibeExe::Crm::Pipeline

    pipeline = VibeExe::Crm::Pipeline.transaction do
      clear_other_defaults if pipeline_params[:default].to_s == 'true'
      VibeExe::Crm::Pipeline.create!(pipeline_params.merge(account: Current.account))
    end
    render json: { pipeline: pipeline_payload(pipeline, include_inactive_stages: true) }, status: :created
  end

  def update
    pipeline = VibeExe::Crm::Pipeline.find_by!(account: Current.account, id: params[:id])
    authorize pipeline

    VibeExe::Crm::Pipeline.transaction do
      if pipeline_params[:default].to_s == 'true'
        clear_other_defaults(pipeline.id)
      end
      pipeline.update!(pipeline_params)
    end

    render json: { pipeline: pipeline_payload(pipeline, include_inactive_stages: true) }
  end

  def destroy
    pipeline = VibeExe::Crm::Pipeline.find_by!(account: Current.account, id: params[:id])
    authorize pipeline

    if pipeline.leads.exists? || pipeline_inbox_default_count(pipeline).positive?
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

  def clear_other_defaults(excluded_id = nil)
    pipelines = VibeExe::Crm::Pipeline.where(account: Current.account)
    pipelines = pipelines.where.not(id: excluded_id) if excluded_id
    pipelines.update_all(default: false)
  end
end
