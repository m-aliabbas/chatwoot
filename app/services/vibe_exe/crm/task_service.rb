class VibeExe::Crm::TaskService
  private

  def record_activity!(task, activity_type, metadata = {})
    task.lead.activities.create!(
      account: task.account,
      user: @user,
      conversation: task.conversation,
      activity_type: activity_type,
      metadata: { task_id: task.id, task_title: task.title }.merge(metadata)
    )
    task.lead.update_column(:last_activity_at, Time.current)
  end
end
