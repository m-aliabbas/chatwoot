class Api::V1::Accounts::VibeExe::Crm::LeadTasksController < Api::V1::Accounts::VibeExe::Crm::TasksController
  before_action :set_lead

  private

  def set_lead
    @lead = VibeExe::Crm::Lead.find_by!(account: Current.account, id: params[:lead_id])
    authorize @lead, :show?
  end

  def task_scope
    super.where(lead: @lead)
  end

  def task_params
    super.merge(lead_id: @lead.id)
  end
end
