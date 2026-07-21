class Api::V1::Accounts::VibeExe::Crm::ConversationLeadsController < Api::V1::Accounts::VibeExe::Crm::BaseController
  before_action :set_conversation

  def index
    authorize VibeExe::Crm::Lead

    render json: linked_leads_payload
  end

  def compatible
    authorize VibeExe::Crm::Lead
    if config.never?
      return render json: {
        leads: [],
        ambiguous: false,
        lead_creation_mode: config.lead_creation_mode
      }
    end

    leads = VibeExe::Crm::FindCompatibleOpenLeadsService.new(
      account: Current.account,
      contact: @conversation.contact,
      pipeline: nil
    ).perform

    render json: {
      leads: leads.map { |lead| lead_summary(lead) },
      ambiguous: leads.many?,
      lead_creation_mode: config.lead_creation_mode
    }
  end

  def create
    authorize VibeExe::Crm::Lead
    return render_disabled_response if config.never?

    lead = VibeExe::Crm::CreateFromConversationService.new(
      conversation: @conversation,
      config: config,
      created_by: Current.user,
      source: 'manual'
    ).perform

    render json: { lead: lead_summary(lead), linked_leads: linked_leads_payload[:leads] }
  end

  def link
    return render_disabled_response if config.never?

    lead = VibeExe::Crm::Lead.find_by!(account: Current.account, id: params[:lead_id])
    authorize lead

    VibeExe::Crm::LinkConversationService.new(
      lead: lead,
      conversation: @conversation,
      linked_by: Current.user,
      source: 'manual'
    ).perform

    render json: { linked_leads: linked_leads_payload[:leads] }
  end

  def unlink
    lead = VibeExe::Crm::Lead.find_by!(account: Current.account, id: params[:id])
    authorize lead, :destroy?

    link = VibeExe::Crm::LeadConversation.find_by!(account: Current.account, conversation: @conversation, lead: lead)
    link.destroy!
    VibeExe::Crm::LeadActivity.create!(
      account: Current.account,
      lead: lead,
      conversation: @conversation,
      user: Current.user,
      activity_type: 'conversation_unlinked',
      metadata: { source: 'manual' }
    )

    render json: { linked_leads: linked_leads_payload[:leads] }
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
  end

  def config
    @config ||= VibeExe::Crm::InboxLeadConfigResolver.new(inbox: @conversation.inbox).perform
  end

  def render_disabled_response
    render json: { error: 'Lead creation is disabled for this inbox' }, status: :forbidden
  end

  def linked_leads_payload
    leads = VibeExe::Crm::Lead
            .joins(:lead_conversations)
            .includes(:pipeline, :pipeline_stage)
            .where(account: Current.account, vibeexe_crm_lead_conversations: { conversation_id: @conversation.id })
            .order('vibeexe_crm_lead_conversations.created_at DESC')

    {
      leads: leads.map { |lead| lead_summary(lead) },
      ambiguous: ambiguous_match?,
      lead_creation_mode: config.lead_creation_mode
    }
  end

  def ambiguous_match?
    (@conversation.additional_attributes || {}).dig('vibeexe_crm', 'automatic_lead_match', 'status') == 'ambiguous'
  end
end
