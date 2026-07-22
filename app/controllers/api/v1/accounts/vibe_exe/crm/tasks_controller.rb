class Api::V1::Accounts::VibeExe::Crm::TasksController < Api::V1::Accounts::VibeExe::Crm::BaseController
  RESULTS_PER_PAGE = 25
  SORT_COLUMNS = %w[due_at created_at updated_at title priority].freeze

  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ArgumentError, with: :render_invalid_filter

  before_action :set_task, only: [:show, :update, :complete, :cancel, :reschedule, :destroy_attachment]

  def index
    authorize VibeExe::Crm::Task
    tasks = filtered_tasks
    paginated_tasks = tasks.page(current_page).per(RESULTS_PER_PAGE)

    render json: {
      tasks: paginated_tasks.map { |task| task_payload(task) },
      meta: { current_page: current_page, total_count: tasks.count, per_page: RESULTS_PER_PAGE }
    }
  end

  def show
    authorize @task
    render json: { task: task_payload(@task) }
  end

  def create
    authorize VibeExe::Crm::Task
    task = VibeExe::Crm::CreateTaskService.new(account: Current.account, user: Current.user, params: task_params).perform
    render json: { task: task_payload(task) }, status: :created
  end

  def update
    authorize @task
    task = VibeExe::Crm::UpdateTaskService.new(task: @task, user: Current.user, params: task_params.except(:lead_id)).perform
    render json: { task: task_payload(task) }
  end

  def complete
    authorize @task, :complete?
    task = VibeExe::Crm::CompleteTaskService.new(task: @task, user: Current.user, completion_note: params[:completion_note]).perform
    render json: { task: task_payload(task) }
  end

  def cancel
    authorize @task, :cancel?
    task = VibeExe::Crm::CancelTaskService.new(task: @task, user: Current.user).perform
    render json: { task: task_payload(task) }
  end

  def reschedule
    authorize @task, :reschedule?
    task = VibeExe::Crm::RescheduleTaskService.new(
      task: @task,
      user: Current.user,
      due_at: params.require(:due_at),
      reminder_at: params[:reminder_at]
    ).perform
    render json: { task: task_payload(task) }
  end

  def destroy_attachment
    authorize @task, :update?
    attachment = @task.files.attachments.find(params[:attachment_id])
    filename = attachment.filename.to_s
    attachment.purge
    record_attachment_removed(filename)
    head :no_content
  end

  private

  def set_task
    @task = task_scope.find(params[:id])
  end

  def task_scope
    VibeExe::Crm::Task
      .includes(lead: :contact)
      .includes(:assignee, :creator, :completer, :conversation)
      .with_attached_files
      .where(account: Current.account)
  end

  def filtered_tasks
    scope = task_scope
    scope = scope.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
    scope = scope.where(creator_id: params[:created_by_id]) if params[:created_by_id].present?
    scope = scope.where(lead_id: params[:lead_id]) if params[:lead_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(task_type: params[:task_type]) if params[:task_type].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where('due_at >= ?', Time.zone.parse(params[:due_from]).beginning_of_day) if params[:due_from].present?
    scope = scope.where('due_at <= ?', Time.zone.parse(params[:due_to]).end_of_day) if params[:due_to].present?
    scope = scope.overdue if params[:overdue].to_s == 'true'
    scope = scope.due_today if params[:due_today].to_s == 'true'
    scope = apply_search(scope)
    apply_sort(scope)
  end

  def apply_search(scope)
    return scope if params[:q].blank?

    query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
    scope.left_joins(:lead).where('vibeexe_crm_tasks.title ILIKE :query OR vibeexe_crm_leads.title ILIKE :query', query: query)
  end

  def apply_sort(scope)
    return scope.worklist_order if params[:sort_by].blank?

    column = SORT_COLUMNS.include?(params[:sort_by]) ? params[:sort_by] : 'due_at'
    direction = params[:sort_direction].to_s.downcase == 'desc' ? :desc : :asc
    scope.order(column => direction, id: :asc)
  end

  def task_params
    params.permit(:lead_id, :assignee_id, :conversation_id, :task_type, :title, :description, :priority, :due_at, :reminder_at, blob_ids: [])
  end

  def task_payload(task)
    {
      id: task.id,
      lead: { id: task.lead_id, title: task.lead.title, contact: contact_payload(task.lead.contact) },
      task_type: task.task_type,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      assignee: user_payload(task.assignee),
      creator: user_payload(task.creator),
      completer: user_payload(task.completer),
      conversation_id: task.conversation_id,
      due_at: task.due_at,
      reminder_at: task.reminder_at,
      completed_at: task.completed_at,
      cancelled_at: task.cancelled_at,
      completion_note: task.completion_note,
      attachments: task.files.map { |file| attachment_payload(file) },
      overdue: task.overdue?,
      can_edit: policy(task).update?,
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end

  def attachment_payload(file)
    {
      id: file.id,
      filename: file.filename.to_s,
      content_type: file.content_type,
      byte_size: file.byte_size,
      file_url: url_for(file)
    }
  end

  def record_attachment_removed(filename)
    @task.lead.activities.create!(
      account: Current.account,
      user: Current.user,
      activity_type: 'task_updated',
      metadata: { task_id: @task.id, task_title: @task.title, attachment_removed: filename }
    )
  end

  def current_page
    (params[:page].presence || 1).to_i
  end

  def render_invalid_filter(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
