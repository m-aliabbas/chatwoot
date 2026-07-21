class VibeExe::Crm::FindCompatibleOpenLeadsService
  pattr_initialize [:account!, :contact!, :pipeline]

  def perform
    scope = VibeExe::Crm::Lead.available_for_contact(account, contact).order(updated_at: :desc, id: :desc)
    return scope unless pipeline.present?

    scope.where(pipeline: pipeline)
  end
end
