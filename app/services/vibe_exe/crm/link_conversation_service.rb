class VibeExe::Crm::LinkConversationService
  pattr_initialize [:lead!, :conversation!, :linked_by, :source!]

  def perform
    lead_conversation = nil

    VibeExe::Crm::LeadConversation.transaction do
      lead_conversation = VibeExe::Crm::LeadConversation.find_or_initialize_by(lead: lead, conversation: conversation)
      return lead_conversation if lead_conversation.persisted?

      lead_conversation.account = lead.account
      lead_conversation.linked_by = linked_by
      lead_conversation.source = source
      lead_conversation.save!

      VibeExe::Crm::LeadActivity.create!(
        account: lead.account,
        lead: lead,
        conversation: conversation,
        user: linked_by,
        activity_type: 'conversation_linked',
        metadata: { source: source }
      )
    end

    lead_conversation
  rescue ActiveRecord::RecordNotUnique
    VibeExe::Crm::LeadConversation.find_by!(lead: lead, conversation: conversation)
  end
end
