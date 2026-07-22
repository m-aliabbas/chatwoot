class Api::V1::Accounts::VibeExe::Crm::LeadTagsController < Api::V1::Accounts::VibeExe::Crm::BaseController
  before_action :set_lead
  before_action :set_label, only: [:create, :destroy]

  def index
    authorize @lead, :show?
    render json: { tags: tag_payloads }
  end

  def create
    authorize @lead, :update?
    VibeExe::Crm::UpdateLeadTagService.new(lead: @lead, label: @label, user: Current.user).add
    render json: { tags: tag_payloads }
  end

  def destroy
    authorize @lead, :update?
    VibeExe::Crm::UpdateLeadTagService.new(lead: @lead, label: @label, user: Current.user).remove
    render json: { tags: tag_payloads }
  end

  private

  def set_lead
    @lead = VibeExe::Crm::Lead.find_by!(account: Current.account, id: params[:lead_id])
  end

  def set_label
    @label = Current.account.labels.find(params[:label_id])
  end

  def tag_payloads
    Current.account.labels.where(title: @lead.label_list.to_a).map do |label|
      { id: label.id, title: label.title, color: label.color }
    end
  end
end
