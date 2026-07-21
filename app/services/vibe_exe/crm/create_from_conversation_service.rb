class VibeExe::Crm::CreateFromConversationService
  pattr_initialize [:conversation!, :config, :created_by, :source!]

  def perform
    VibeExe::Crm::Lead.transaction do
      lead = VibeExe::Crm::Lead.create!(
        account: account,
        contact: conversation.contact,
        pipeline: pipeline,
        pipeline_stage: pipeline_stage,
        owner: config&.default_owner,
        team: config&.default_team,
        created_by: created_by,
        title: lead_title,
        source: channel_source,
        status: :open,
        priority: :medium,
        metadata: {
          inbox_id: conversation.inbox_id,
          conversation_display_id: conversation.display_id,
          creation_source: source
        }
      )

      VibeExe::Crm::LeadActivity.create!(
        account: account,
        lead: lead,
        conversation: conversation,
        user: created_by,
        activity_type: 'lead_created',
        metadata: { source: source, channel_source: channel_source }
      )

      VibeExe::Crm::LinkConversationService.new(
        lead: lead,
        conversation: conversation,
        linked_by: created_by,
        source: source
      ).perform

      lead
    end
  end

  private

  def account
    conversation.account
  end

  def pipeline
    @pipeline ||= config&.default_pipeline || account_default_pipeline
  end

  def account_default_pipeline
    VibeExe::Crm::Pipeline.active.where(account: account).ordered.first!
  end

  def pipeline_stage
    @pipeline_stage ||= pipeline.stages.active.ordered.first!
  end

  def lead_title
    identity = conversation.contact.name.presence || conversation.contact.email.presence || conversation.contact.phone_number.presence
    "#{identity || 'Unknown contact'} from #{conversation.inbox.name}"
  end

  def channel_source
    @channel_source ||= VibeExe::Crm::SourceMapper.new(inbox: conversation.inbox).perform
  end
end
