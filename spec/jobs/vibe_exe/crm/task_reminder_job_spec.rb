require 'rails_helper'

RSpec.describe VibeExe::Crm::TaskReminderJob, type: :job do
  let(:account) { create(:account) }
  let(:creator) { create(:user, account: account, role: :administrator) }
  let(:assignee) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account) }
  let(:pipeline) { VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales') }
  let(:stage) { VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New') }
  let(:lead) do
    VibeExe::Crm::Lead.create!(account: account, contact: contact, pipeline: pipeline, pipeline_stage: stage, title: 'Reminder lead', source: 'manual')
  end

  it 'delivers one in-app reminder to the assignee' do
    task = create_task(reminder_at: 1.minute.ago)

    expect { described_class.perform_now }.to change(Notification.task_reminder, :count).by(1)
    expect { described_class.perform_now }.not_to change(Notification, :count)

    notification = Notification.task_reminder.find_by!(primary_actor: task)
    expect(notification.user).to eq(assignee)
    expect(task.reload.reminder_sent_at).to be_present
  end

  it 'ignores completed, cancelled, unassigned, and future reminders' do
    completed = create_task(reminder_at: 1.minute.ago)
    completed.update!(status: :completed, completed_at: Time.current, completer: creator, reminder_at: nil)
    cancelled = create_task(reminder_at: 1.minute.ago)
    cancelled.update!(status: :cancelled, cancelled_at: Time.current, reminder_at: nil)
    create_task(reminder_at: 1.minute.ago, assignee: nil)
    create_task(reminder_at: 1.hour.from_now)

    expect { described_class.perform_now }.not_to change(Notification.task_reminder, :count)
  end

  def create_task(reminder_at:, assignee: self.assignee)
    VibeExe::Crm::Task.create!(
      account: account,
      lead: lead,
      creator: creator,
      assignee: assignee,
      title: "Reminder #{SecureRandom.hex(3)}",
      task_type: :follow_up,
      priority: :medium,
      due_at: 1.day.from_now,
      reminder_at: reminder_at
    )
  end
end
