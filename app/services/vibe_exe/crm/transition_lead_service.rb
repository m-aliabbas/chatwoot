class VibeExe::Crm::TransitionLeadService
  def initialize(lead:, user:, params:)
    @lead = lead
    @user = user
    @params = params
  end

  def change_stage!
    stage = VibeExe::Crm::PipelineStage.active.find_by!(account: @lead.account, id: @params.fetch(:pipeline_stage_id))
    update_params = { pipeline: stage.pipeline, pipeline_stage: stage }
    update_params.merge!(status_params_for(stage))
    VibeExe::Crm::UpdateLeadService.new(lead: @lead, user: @user, params: update_params).perform
  end

  def mark_won!
    @lead.update!(status: :won, closed_status: 'won', closed_reason: nil, closed_at: Time.zone.now, archived_at: nil)
    create_activity('status_changed', { to: 'won' })
    @lead
  end

  def mark_lost!
    @lead.update!(status: :lost, closed_status: 'lost', closed_reason: @params[:closed_reason], closed_at: Time.zone.now, archived_at: nil)
    create_activity('status_changed', { to: 'lost', reason: @params[:closed_reason] })
    @lead
  end

  def archive!
    @lead.update!(archived_at: Time.zone.now)
    create_activity('status_changed', { archived: true })
    @lead
  end

  def restore!
    @lead.update!(archived_at: nil)
    create_activity('status_changed', { archived: false })
    @lead
  end

  private

  def status_params_for(stage)
    return { status: :won, closed_status: 'won', closed_reason: nil, closed_at: Time.zone.now, archived_at: nil } if stage.won_stage?
    return { status: :lost, closed_status: 'lost', closed_reason: @params[:closed_reason], closed_at: Time.zone.now, archived_at: nil } if stage.lost_stage?

    { status: :open, closed_status: nil, closed_reason: nil, closed_at: nil }
  end

  def create_activity(activity_type, metadata)
    VibeExe::Crm::LeadActivity.create!(
      account: @lead.account,
      lead: @lead,
      user: @user,
      activity_type: activity_type,
      metadata: metadata
    )
    @lead.update_column(:last_activity_at, Time.zone.now)
  end
end
