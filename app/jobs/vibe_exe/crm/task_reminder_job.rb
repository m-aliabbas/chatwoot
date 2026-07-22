class VibeExe::Crm::TaskReminderJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    VibeExe::Crm::Task.reminders_due.includes(:account, :assignee, :lead).find_each(batch_size: 100) do |task|
      deliver(task)
    end
  end

  private

  def deliver(task)
    task.with_lock do
      next unless eligible?(task)

      notification = Notification.find_or_initialize_by(account: task.account, primary_actor: task)
      notification.assign_attributes(
        user: task.assignee,
        notification_type: :task_reminder,
        secondary_actor: nil,
        read_at: nil,
        last_activity_at: Time.current,
        meta: { lead_id: task.lead_id, task_id: task.id, due_at: task.due_at }
      )
      notification.save!
      task.update!(reminder_sent_at: Time.current)
    end
  end

  def eligible?(task)
    task.pending? &&
      task.assignee.present? &&
      task.reminder_at.present? &&
      task.reminder_at <= Time.current &&
      task.reminder_sent_at.nil? &&
      task.assignee.account_users.exists?(account_id: task.account_id)
  end
end
