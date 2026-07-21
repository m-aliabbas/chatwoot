class Api::V1::Accounts::VibeExe::Crm::LeadConversationsController < Api::V1::Accounts::VibeExe::Crm::BaseController
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  before_action :set_lead

  def index
    authorize @lead

    conversations = @lead.conversations.includes(:inbox, :assignee, :team, :messages).order(updated_at: :desc)
    render json: {
      conversations: conversations.map { |conversation| conversation_payload(conversation) },
      candidates: candidate_conversations.map { |conversation| conversation_payload(conversation) }
    }
  end

  def create
    authorize @lead, :update?

    conversation = Current.account.conversations.find_by!(id: params.require(:conversation_id), contact_id: @lead.contact_id)
    VibeExe::Crm::LinkConversationService.new(lead: @lead, conversation: conversation, linked_by: Current.user, source: 'manual').perform
    render json: { conversations: @lead.conversations.includes(:inbox, :assignee, :team, :messages).order(updated_at: :desc).map { |item| conversation_payload(item) } }
  end

  def destroy
    authorize @lead, :destroy?

    conversation = Current.account.conversations.find(params[:id])
    link = VibeExe::Crm::LeadConversation.find_by!(account: Current.account, lead: @lead, conversation: conversation)
    link.destroy!
    VibeExe::Crm::LeadActivity.create!(
      account: Current.account,
      lead: @lead,
      conversation: conversation,
      user: Current.user,
      activity_type: 'conversation_unlinked',
      metadata: { source: 'manual' }
    )
    @lead.update_column(:last_activity_at, Time.zone.now)
    render json: { conversations: @lead.conversations.includes(:inbox, :assignee, :team, :messages).order(updated_at: :desc).map { |item| conversation_payload(item) } }
  end

  private

  def set_lead
    @lead = VibeExe::Crm::Lead.find_by!(account: Current.account, id: params[:lead_id])
  end

  def candidate_conversations
    Current.account
           .conversations
           .includes(:inbox, :assignee, :team, :messages)
           .where(contact_id: @lead.contact_id)
           .where.not(id: @lead.conversation_ids)
           .order(updated_at: :desc)
           .limit(10)
  end

  def conversation_payload(conversation)
    last_message = conversation.messages.last
    {
      id: conversation.id,
      display_id: conversation.display_id,
      inbox_name: conversation.inbox.name,
      status: conversation.status,
      assignee_name: conversation.assignee&.available_name,
      team_name: conversation.team&.name,
      last_message: last_message&.content,
      updated_at: conversation.updated_at
    }
  end
end
