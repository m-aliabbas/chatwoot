require 'rails_helper'

RSpec.describe 'VibeExe CRM Tasks API', type: :request do
  let!(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:assignee) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account) }
  let(:pipeline) { VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales') }
  let(:stage) { VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New') }
  let(:lead) do
    VibeExe::Crm::Lead.create!(
      account: account,
      contact: contact,
      pipeline: pipeline,
      pipeline_stage: stage,
      title: 'Qualified buyer',
      source: 'manual'
    )
  end
  let(:headers) { admin.create_new_auth_token }
  let(:base_url) { "/api/v1/accounts/#{account.id}/vibeexe/crm/tasks" }

  before { account.enable_features!(:crm) }

  it 'creates an account-scoped task and activity' do
    expect do
      post base_url,
           params: {
             lead_id: lead.id,
             assignee_id: assignee.id,
             title: 'Call buyer',
             task_type: 'call',
             priority: 'high',
             due_at: 1.day.from_now,
             reminder_at: 1.hour.from_now
           },
           headers: headers,
           as: :json
    end.to change(VibeExe::Crm::Task, :count).by(1)
      .and change(VibeExe::Crm::LeadActivity.where(activity_type: 'task_created'), :count).by(1)

    expect(response).to have_http_status(:created), response.body
  end

  it 'rejects a reminder after the due time' do
    post base_url,
         params: {
           lead_id: lead.id,
           title: 'Invalid reminder',
           task_type: 'general',
           priority: 'medium',
           due_at: 1.hour.from_now,
           reminder_at: 2.hours.from_now
         },
         headers: headers,
         as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('errors', 'reminder_at')).to be_present
  end

  it 'filters by assignee, lead, creator, priority, and due range' do
    task = VibeExe::Crm::Task.create!(
      account: account,
      lead: lead,
      creator: admin,
      assignee: assignee,
      title: 'Matching task',
      task_type: :follow_up,
      priority: :urgent,
      due_at: Time.zone.now.change(hour: 12) + 1.day
    )

    get base_url,
        params: {
          assignee_id: assignee.id,
          lead_id: lead.id,
          created_by_id: admin.id,
          priority: 'urgent',
          due_from: 1.day.from_now.to_date,
          due_to: 1.day.from_now.to_date
        },
        headers: headers,
        as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['tasks'].pluck('id')).to eq([task.id])
    expect(response.parsed_body['summary']).to include(
      'total_count' => 1,
      'pending_count' => 1,
      'completed_count' => 0
    )
  end

  it 'completes idempotently with a completion note' do
    task = VibeExe::Crm::Task.create!(
      account: account,
      lead: lead,
      creator: admin,
      assignee: assignee,
      title: 'Follow up',
      task_type: :follow_up,
      priority: :medium,
      due_at: 1.day.from_now
    )

    expect do
      patch "#{base_url}/#{task.id}/complete", params: { completion_note: 'Customer confirmed' }, headers: headers, as: :json
      patch "#{base_url}/#{task.id}/complete", params: { completion_note: 'Customer confirmed' }, headers: headers, as: :json
    end.to change(VibeExe::Crm::LeadActivity.where(activity_type: 'task_completed'), :count).by(1)

    expect(task.reload).to be_completed
    expect(task.completion_note).to eq('Customer confirmed')
  end

  it 'does not expose a task from another account' do
    other_account = create(:account)
    other_user = create(:user, account: other_account, role: :administrator)
    other_contact = create(:contact, account: other_account)
    other_pipeline = VibeExe::Crm::Pipeline.create!(account: other_account, name: 'Other')
    other_stage = VibeExe::Crm::PipelineStage.create!(account: other_account, pipeline: other_pipeline, name: 'New')
    other_lead = VibeExe::Crm::Lead.create!(
      account: other_account, contact: other_contact, pipeline: other_pipeline, pipeline_stage: other_stage, title: 'Other', source: 'manual'
    )
    task = VibeExe::Crm::Task.create!(
      account: other_account, lead: other_lead, creator: other_user, title: 'Private task', task_type: :general, priority: :medium, due_at: 1.day.from_now
    )

    get "#{base_url}/#{task.id}", headers: headers, as: :json

    expect(response).to have_http_status(:not_found)
  end

end
