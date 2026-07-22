class VibeExe::Crm::BootstrapDefaultPipelineService
  STAGES = [
    ['New', :open_stage, 0],
    ['Contacted', :open_stage, 10],
    ['Qualified', :open_stage, 30],
    ['Viewing', :open_stage, 50],
    ['Negotiation', :open_stage, 80],
    ['Won', :won_stage, 100],
    ['Lost', :lost_stage, 0]
  ].freeze

  def initialize(account:)
    @account = account
  end

  def perform
    pipeline = nil

    VibeExe::Crm::Pipeline.transaction do
      pipeline = VibeExe::Crm::Pipeline.find_or_create_by!(account: @account, name: 'Sales Pipeline') do |record|
        record.position = 0
        record.active = true
      end
      VibeExe::Crm::Pipeline.where(account: @account).where.not(id: pipeline.id).update_all(default: false)
      pipeline.update!(default: true, active: true)

      STAGES.each_with_index do |(name, stage_type, probability), index|
        VibeExe::Crm::PipelineStage.find_or_create_by!(account: @account, pipeline: pipeline, name: name) do |stage|
          stage.default = index.zero?
          stage.position = index
          stage.stage_type = stage_type
          stage.probability = probability
        end
      end

      default_stage = pipeline.stages.find_by!(name: STAGES.first.first)
      pipeline.stages.where.not(id: default_stage.id).update_all(default: false)
      default_stage.update!(default: true)
    end

    pipeline
  end
end
