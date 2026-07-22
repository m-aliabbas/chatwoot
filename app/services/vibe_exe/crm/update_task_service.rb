class VibeExe::Crm::UpdateTaskService < VibeExe::Crm::TaskService
  TRACKED_FIELDS = %w[task_type title description priority assignee_id due_at reminder_at conversation_id].freeze

  def initialize(task:, user:, params:)
    @task = task
    @user = user
    @params = params
  end

  def perform
    VibeExe::Crm::Task.transaction do
      blob_ids = @params.delete(:blob_ids) || []
      @task.assign_attributes(@params)
      changes = @task.changes.slice(*TRACKED_FIELDS)
      blob_ids.each { |blob_id| @task.files.attach(ActiveStorage::Blob.find_signed!(blob_id)) }
      return @task if changes.blank? && blob_ids.blank?

      @task.reminder_sent_at = nil if changes.key?('reminder_at')
      @task.save!
      record_activity!(@task, 'task_updated', changes: changes, attachments_added: blob_ids.length)
      @task
    end
  end
end
