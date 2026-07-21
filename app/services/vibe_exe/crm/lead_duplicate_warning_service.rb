class VibeExe::Crm::LeadDuplicateWarningService
  def initialize(account:, contact:, pipeline: nil, external_id: nil, exclude_lead: nil)
    @account = account
    @contact = contact
    @pipeline = pipeline
    @external_id = external_id
    @exclude_lead = exclude_lead
  end

  def perform
    candidates = open_leads
    candidates = candidates.where.not(id: @exclude_lead.id) if @exclude_lead.present?

    {
      same_contact_open_leads: lead_payloads(candidates.limit(5)),
      same_pipeline_candidates: lead_payloads(candidates.where(pipeline: @pipeline).limit(5)),
      matching_external_id_candidates: matching_external_id_candidates
    }
  end

  private

  def open_leads
    VibeExe::Crm::Lead.active.open.includes(:contact, :pipeline, :pipeline_stage, :owner).where(account: @account, contact: @contact)
  end

  def matching_external_id_candidates
    return [] if @external_id.blank?

    lead_payloads(
      VibeExe::Crm::Lead
        .active
        .open
        .includes(:contact, :pipeline, :pipeline_stage, :owner)
        .where(account: @account)
        .where("metadata ->> 'external_id' = ?", @external_id.to_s)
        .limit(5)
    )
  end

  def lead_payloads(leads)
    leads.map do |lead|
      {
        id: lead.id,
        title: lead.title,
        contact_name: lead.contact.name,
        pipeline_name: lead.pipeline.name,
        pipeline_stage_name: lead.pipeline_stage.name,
        owner_name: lead.owner&.available_name,
        updated_at: lead.updated_at
      }
    end
  end
end
