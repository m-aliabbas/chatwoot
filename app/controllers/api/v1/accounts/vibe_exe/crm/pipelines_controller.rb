class Api::V1::Accounts::VibeExe::Crm::PipelinesController < Api::V1::Accounts::VibeExe::Crm::BaseController
  def index
    authorize VibeExe::Crm::Lead

    pipelines = VibeExe::Crm::Pipeline.active.where(account: Current.account).ordered.includes(:stages)
    render json: pipelines.map { |pipeline| pipeline_payload(pipeline) }
  end

  private

  def pipeline_payload(pipeline)
    {
      id: pipeline.id,
      name: pipeline.name,
      default: pipeline.default,
      stages: pipeline.stages.active.ordered.map do |stage|
        {
          id: stage.id,
          name: stage.name,
          default: stage.default
        }
      end
    }
  end
end
