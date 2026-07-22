class VibeExe::Crm::RescheduleTaskService < VibeExe::Crm::TaskService
  def initialize(task:, user:, due_at:, reminder_at: nil)
    @task = task
    @user = user
    @due_at = due_at
    @reminder_at = reminder_at
  end

  def perform
    @task.transaction do
      old_due_at = @task.due_at
      @task.update!(due_at: @due_at, reminder_at: @reminder_at, reminder_sent_at: nil)
      record_activity!(@task, 'task_rescheduled', old_due_at: old_due_at, new_due_at: @task.due_at, reminder_at: @task.reminder_at)
      @task
    end
  end
end
