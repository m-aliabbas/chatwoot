class VibeExe::Crm::CancelTaskService < VibeExe::Crm::TaskService
  def initialize(task:, user:)
    @task = task
    @user = user
  end

  def perform
    return @task if @task.cancelled?

    @task.transaction do
      @task.update!(
        status: :cancelled,
        cancelled_at: Time.current,
        completed_at: nil,
        completer: nil,
        reminder_at: nil
      )
      record_activity!(@task, 'task_cancelled')
      @task
    end
  end
end
