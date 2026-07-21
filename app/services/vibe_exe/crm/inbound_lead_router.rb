class VibeExe::Crm::InboundLeadRouter
  pattr_initialize [:message!, :performed_by]

  def perform
    return unless message.account.feature_enabled?('crm')
    return unless qualifying_message?

    message.conversation.with_lock do
      return if linked_conversation?

      config = VibeExe::Crm::InboxLeadConfigResolver.new(inbox: message.inbox).perform
      return unless config.automatic?
      return unless first_qualifying_message?

      compatible_leads = VibeExe::Crm::FindCompatibleOpenLeadsService.new(
        account: message.account,
        contact: message.conversation.contact,
        pipeline: config.default_pipeline
      ).perform

      if compatible_leads.one?
        link_lead(compatible_leads.first)
      elsif compatible_leads.many?
        record_ambiguous_match(compatible_leads)
      else
        VibeExe::Crm::CreateFromConversationService.new(
          conversation: message.conversation,
          config: config,
          created_by: nil,
          source: 'automatic'
        ).perform
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "VibeExe CRM lead routing failed: #{e.class} #{e.message}"
  end

  private

  def qualifying_message?
    message.incoming? &&
      !message.private? &&
      message.sender.is_a?(Contact) &&
      message.conversation.present? &&
      message.conversation.contact.present? &&
      !internal_automation_message?
  end

  def internal_automation_message?
    performed_by.is_a?(AutomationRule) || message.content_attributes&.key?('automation_rule_id')
  end

  def first_qualifying_message?
    !message.conversation.messages
            .where(message_type: :incoming, private: false, sender_type: 'Contact')
            .where.not(id: message.id)
            .where('id < ?', message.id)
            .exists?
  end

  def linked_conversation?
    VibeExe::Crm::LeadConversation.exists?(account: message.account, conversation: message.conversation)
  end

  def link_lead(lead)
    VibeExe::Crm::LinkConversationService.new(
      lead: lead,
      conversation: message.conversation,
      linked_by: nil,
      source: 'automatic'
    ).perform
  end

  def record_ambiguous_match(leads)
    lead_ids = leads.pluck(:id)
    additional_attributes = message.conversation.additional_attributes || {}
    crm_attributes = additional_attributes['vibeexe_crm'] || {}
    crm_attributes['automatic_lead_match'] = {
      'status' => 'ambiguous',
      'lead_ids' => lead_ids,
      'message_id' => message.id,
      'recorded_at' => Time.zone.now.iso8601
    }
    additional_attributes['vibeexe_crm'] = crm_attributes
    message.conversation.update!(additional_attributes: additional_attributes)

    VibeExe::Crm::LeadActivity.create!(
      account: message.account,
      conversation: message.conversation,
      activity_type: 'automatic_link_skipped_ambiguous',
      metadata: {
        lead_ids: lead_ids,
        inbox_id: message.inbox_id,
        message_id: message.id,
        contact_id: message.sender_id
      }
    )
  end
end
