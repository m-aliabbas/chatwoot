class Api::V1::Accounts::VibeExe::Crm::PipelineStagesController < Api::V1::Accounts::VibeExe::Crm::BaseController
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  before_action :set_pipeline

  def create
    authorize @pipeline, :update?

    stage = VibeExe::Crm::PipelineStage.transaction do
      @pipeline.stages.update_all(default: false) if stage_params[:default].to_s == 'true'
      @pipeline.stages.create!(stage_params.merge(account: Current.account))
    end
    render json: { stage: stage_payload(stage) }, status: :created
  end

  def update
    stage = @pipeline.stages.find_by!(account: Current.account, id: params[:id])
    authorize @pipeline, :update?
    if removes_last_active_open_stage?(stage)
      return render json: { error: 'Active pipelines must have at least one active open stage' }, status: :unprocessable_entity
    end

    VibeExe::Crm::PipelineStage.transaction do
      if stage_params[:default].to_s == 'true'
        @pipeline.stages.where.not(id: stage.id).update_all(default: false)
      end
      stage.update!(stage_params)
    end

    render json: { stage: stage_payload(stage) }
  end

  def destroy
    stage = @pipeline.stages.find_by!(account: Current.account, id: params[:id])
    authorize @pipeline, :update?
    if stage.open_stage? && stage.active? && active_open_stage_count == 1
      return render json: { error: 'Active pipelines must have at least one active open stage' }, status: :unprocessable_entity
    end

    if stage.leads.exists? || VibeExe::Crm::InboxLeadConfig.exists?(account: Current.account, default_stage: stage)
      return render json: { error: 'Stage is used by leads or inbox defaults' }, status: :unprocessable_entity
    end

    stage.destroy!
    head :ok
  end

  def reorder
    authorize @pipeline, :update?

    stage_ids = Array(params[:stage_ids]).map(&:to_i)
    existing_ids = @pipeline.stages.where(account: Current.account).pluck(:id)
    unless stage_ids.length == existing_ids.length && stage_ids.uniq.sort == existing_ids.sort
      return render json: { error: 'Stage order must include every pipeline stage exactly once' }, status: :unprocessable_entity
    end

    VibeExe::Crm::PipelineStage.transaction do
      stage_ids.each_with_index do |stage_id, position|
        @pipeline.stages.where(account: Current.account, id: stage_id).update_all(position: position)
      end
    end

    render json: { pipeline: pipeline_payload(@pipeline, include_inactive_stages: true) }
  end

  private

  def set_pipeline
    @pipeline = VibeExe::Crm::Pipeline.find_by!(account: Current.account, id: params[:pipeline_id])
  end

  def stage_params
    params.permit(:name, :active, :default, :position, :stage_type, :probability)
  end

  def removes_last_active_open_stage?(stage)
    return false unless @pipeline.active?
    return false unless stage.open_stage? && stage.active? && active_open_stage_count == 1

    stage_params[:active].to_s == 'false' || stage_params[:stage_type].present? && stage_params[:stage_type] != 'open_stage'
  end

  def active_open_stage_count
    @pipeline.stages.active.open_stage.count
  end
end
