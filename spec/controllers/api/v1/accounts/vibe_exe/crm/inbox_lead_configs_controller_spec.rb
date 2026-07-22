require 'rails_helper'

RSpec.describe 'VibeExe CRM Inbox Lead Config API', type: :request do
  let!(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:pipeline) { VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales') }
  let(:stage) { VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New', default: true) }
  let(:url) { "/api/v1/accounts/#{account.id}/vibeexe/crm/inboxes/#{inbox.id}/lead_config" }

  before do
    account.enable_features!(:crm)
  end

  it 'allows an administrator to select inbox CRM defaults' do
    patch url,
          params: { lead_creation_mode: 'automatic', default_pipeline_id: pipeline.id, default_stage_id: stage.id },
          headers: admin.create_new_auth_token,
          as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to include(
      'lead_creation_mode' => 'automatic',
      'default_pipeline_id' => pipeline.id,
      'default_stage_id' => stage.id
    )
  end

  it 'rejects inbox CRM configuration by an agent' do
    get url, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it 'rejects a start stage from another pipeline' do
    other_pipeline = VibeExe::Crm::Pipeline.create!(account: account, name: 'Other')
    other_stage = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: other_pipeline, name: 'Other stage')

    patch url,
          params: { default_pipeline_id: pipeline.id, default_stage_id: other_stage.id },
          headers: admin.create_new_auth_token,
          as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
