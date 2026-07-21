class VibeExe::Crm::LeadPolicy < ApplicationPolicy
  def index?
    crm_user?
  end

  def show?
    crm_user?
  end

  def create?
    crm_user?
  end

  def compatible?
    index?
  end

  def link?
    update?
  end

  def unlink?
    destroy?
  end

  def update?
    crm_user?
  end

  def destroy?
    crm_user?
  end

  private

  def crm_user?
    @account_user.administrator? || @account_user.agent?
  end
end
