class VibeExe::Crm::InboxLeadConfigResolver
  pattr_initialize [:inbox!]

  def perform
    VibeExe::Crm::InboxLeadConfig.find_or_initialize_by(account: inbox.account, inbox: inbox) do |config|
      config.lead_creation_mode = :manual
    end
  end
end
