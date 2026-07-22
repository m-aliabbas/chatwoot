class VibeExe::Crm::CreateTaskService < VibeExe::Crm::TaskService
  def initialize(account:, user:, params:)
    @account = account
    @user = user
    @params = params
  end

  def perform
    VibeExe::Crm::Task.transaction do
      blob_ids = @params.delete(:blob_ids) || []
      task = VibeExe::Crm::Task.new(@params.merge(account: @account, creator: @user))
      blob_ids.each { |blob_id| task.files.attach(ActiveStorage::Blob.find_signed!(blob_id)) }
      task.save!
      record_activity!(task, 'task_created', task.snapshot)
      task
    end
  end
end
