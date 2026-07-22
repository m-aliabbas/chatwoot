class VibeExe::Crm::TaskPolicy < ApplicationPolicy
  def index?
    crm_user?
  end

  def show?
    crm_user?
  end

  def create?
    crm_user?
  end

  def update?
    administrator? || record.creator_id == user.id || record.assignee_id == user.id
  end

  def complete?
    update?
  end

  def cancel?
    update?
  end

  def reschedule?
    update?
  end

  private

  def crm_user?
    administrator? || account_user.agent?
  end

  def administrator?
    account_user.administrator?
  end
end
