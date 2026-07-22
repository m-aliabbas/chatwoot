class VibeExe::Crm::LeadNotePolicy < ApplicationPolicy
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
    administrator? || record.author_id == user.id
  end

  def destroy?
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
