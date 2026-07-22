class Api::V1::Accounts::VibeExe::Crm::BaseController < Api::V1::Accounts::BaseController
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  before_action :ensure_crm_enabled

  private

  def render_not_found
    render json: { error: 'Resource could not be found' }, status: :not_found
  end

  def ensure_crm_enabled
    return if Current.account.feature_enabled?('crm')

    render json: { error: 'CRM is not enabled for this account' }, status: :forbidden
  end

  def lead_summary(lead)
    {
      id: lead.id,
      title: lead.title,
      status: lead.status,
      priority: lead.priority,
      source: lead.source,
      estimated_value: lead.estimated_value&.to_s,
      currency: lead.currency,
      expected_close_date: lead.expected_close_date,
      archived_at: lead.archived_at,
      closed_at: lead.closed_at,
      closed_reason: lead.closed_reason,
      pipeline_id: lead.pipeline_id,
      pipeline_name: lead.pipeline.name,
      pipeline_stage_id: lead.pipeline_stage_id,
      pipeline_stage_name: lead.pipeline_stage.name,
      owner_id: lead.owner_id,
      owner_name: lead.owner&.available_name,
      team_id: lead.team_id,
      team_name: lead.team&.name,
      contact: contact_payload(lead.contact),
      tags: lead_tags_payload(lead),
      last_activity_at: lead.last_activity_at,
      created_at: lead.created_at,
      updated_at: lead.updated_at
    }
  end

  def lead_detail_payload(lead)
    lead_summary(lead).merge(
      metadata: lead.metadata,
      duplicate_warnings: duplicate_warnings_for(lead),
      productivity_summary: productivity_summary(lead)
    )
  end

  def lead_tags_payload(lead)
    lead.tags.filter_map do |tag|
      label = account_labels_by_title[tag.name]
      { id: label.id, title: label.title, color: label.color } if label
    end
  end

  def account_labels_by_title
    @account_labels_by_title ||= Current.account.labels.index_by(&:title)
  end

  def productivity_summary(lead)
    pending_tasks = lead.tasks.pending
    {
      open_tasks_count: pending_tasks.count,
      overdue_tasks_count: pending_tasks.where('due_at < ?', Time.current).count,
      next_task_due_at: pending_tasks.minimum(:due_at)
    }
  end

  def pipeline_payload(pipeline, include_inactive_stages: false)
    stages = include_inactive_stages ? pipeline.stages : pipeline.stages.active

    {
      id: pipeline.id,
      name: pipeline.name,
      default: pipeline.default,
      active: pipeline.active,
      position: pipeline.position,
      lead_count: pipeline.leads.count,
      inbox_default_count: pipeline_inbox_default_count(pipeline),
      stages: stages.ordered.map { |stage| stage_payload(stage) }
    }
  end

  def stage_payload(stage)
    {
      id: stage.id,
      pipeline_id: stage.pipeline_id,
      name: stage.name,
      default: stage.default,
      active: stage.active,
      position: stage.position,
      stage_type: stage.stage_type,
      probability: stage.probability,
      lead_count: stage.leads.count,
      inbox_default_count: VibeExe::Crm::InboxLeadConfig.where(account: Current.account, default_stage: stage).count
    }
  end

  def pipeline_inbox_default_count(pipeline)
    configs = VibeExe::Crm::InboxLeadConfig.where(account: Current.account)
    configs.where(default_pipeline: pipeline).or(configs.where(default_stage_id: pipeline.stage_ids)).count
  end

  def contact_payload(contact)
    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number
    }
  end

  def user_payload(user)
    return if user.blank?

    {
      id: user.id,
      name: user.available_name,
      email: user.email
    }
  end

  def duplicate_warnings_for(lead)
    VibeExe::Crm::LeadDuplicateWarningService.new(
      account: Current.account,
      contact: lead.contact,
      pipeline: lead.pipeline,
      external_id: lead.metadata&.dig('external_id'),
      exclude_lead: lead
    ).perform
  end

  def render_record_invalid(error)
    render json: {
      error: error.record.errors.full_messages.to_sentence,
      errors: error.record.errors.to_hash(true)
    }, status: :unprocessable_entity
  end
end
