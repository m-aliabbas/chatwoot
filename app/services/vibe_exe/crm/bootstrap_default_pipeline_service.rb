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
        record.default = true
        record.position = 0
        record.active = true
      end

      STAGES.each_with_index do |(name, stage_type, probability), index|
        VibeExe::Crm::PipelineStage.find_or_create_by!(account: @account, pipeline: pipeline, name: name) do |stage|
          stage.default = index.zero?
          stage.position = index
          stage.stage_type = stage_type
          stage.probability = probability
        end
      end
    end

    pipeline
  end
end
