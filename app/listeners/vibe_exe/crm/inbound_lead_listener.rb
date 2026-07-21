class VibeExe::Crm::InboundLeadListener < BaseListener
  def message_created(event)
    VibeExe::Crm::InboundLeadRouter.new(
      message: event.data[:message],
      performed_by: event.data[:performed_by]
    ).perform
  end
end
