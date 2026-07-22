class VibeExe::Crm::CompleteTaskService < VibeExe::Crm::TaskService
  def initialize(task:, user:, completion_note: nil)
    @task = task
    @user = user
    @completion_note = completion_note
  end

  def perform
    return @task if @task.completed?

    @task.transaction do
      @task.update!(
        status: :completed,
        completed_at: Time.current,
        completer: @user,
        completion_note: @completion_note,
        cancelled_at: nil,
        reminder_at: nil
      )
      record_activity!(@task, 'task_completed', completion_note: @task.completion_note&.truncate(160))
      @task
    end
  end
end
