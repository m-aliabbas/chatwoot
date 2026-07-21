class VibeExe::Crm::CreateLeadService
  def initialize(account:, user:, params:)
    @account = account
    @user = user
    @params = params
  end

  def perform
    lead = nil

    VibeExe::Crm::Lead.transaction do
      lead = VibeExe::Crm::Lead.create!(@params.merge(account: @account, created_by: @user))
      create_activity(lead, 'lead_created')
    end

    lead
  end

  private

  def create_activity(lead, activity_type, metadata = {})
    VibeExe::Crm::LeadActivity.create!(
      account: @account,
      lead: lead,
      user: @user,
      activity_type: activity_type,
      metadata: metadata
    )
    lead.update_column(:last_activity_at, Time.zone.now)
  end
end
