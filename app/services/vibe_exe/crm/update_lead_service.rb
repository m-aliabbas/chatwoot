class VibeExe::Crm::UpdateLeadService
  ACTIVITY_BY_ATTRIBUTE = {
    'pipeline_id' => 'pipeline_changed',
    'pipeline_stage_id' => 'stage_changed',
    'owner_id' => 'owner_changed',
    'team_id' => 'team_changed',
    'status' => 'status_changed'
  }.freeze

  def initialize(lead:, user:, params:)
    @lead = lead
    @user = user
    @params = params
  end

  def perform
    VibeExe::Crm::Lead.transaction do
      before_values = tracked_values
      @lead.update!(@params)
      create_change_activities(before_values)
    end

    @lead
  end

  private

  def tracked_values
    ACTIVITY_BY_ATTRIBUTE.keys.index_with { |attribute| @lead.public_send(attribute) }
  end

  def create_change_activities(before_values)
    ACTIVITY_BY_ATTRIBUTE.each do |attribute, activity_type|
      next unless @lead.saved_change_to_attribute?(attribute)

      create_activity(activity_type, { from: before_values[attribute], to: @lead.public_send(attribute) })
    end
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
