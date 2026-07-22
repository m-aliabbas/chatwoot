require 'rails_helper'

RSpec.describe 'VibeExe CRM Pipelines API', type: :request do
  let!(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:headers) { admin.create_new_auth_token }
  let(:base_url) { "/api/v1/accounts/#{account.id}/vibeexe/crm/pipelines" }

  before do
    account.enable_features!(:crm)
  end

  describe 'GET /api/v1/accounts/:account_id/vibeexe/crm/pipelines' do
    it 'returns an empty state when no pipeline exists' do
      get base_url, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq([])
    end

    it 'returns inactive pipelines, ordered stages, and dependency counts for administration' do
      pipeline = VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales')
      later_stage = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'Later', position: 2)
      first_stage = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'First', position: 0)
      lead = VibeExe::Crm::Lead.create!(account: account, contact: create(:contact, account: account), pipeline: pipeline,
                                       pipeline_stage: first_stage, title: 'Lead', source: 'manual')
      pipeline.update!(active: false)

      get base_url, params: { include_inactive: true }, headers: headers, as: :json

      payload = response.parsed_body.first
      expect(payload['lead_count']).to eq(1)
      expect(payload['stages'].pluck('id')).to eq([first_stage.id, later_stage.id])
      expect(payload['stages'].first['lead_count']).to eq(1)
      expect(lead).to be_present
    end

    it 'rejects the administration view for an agent' do
      get base_url, params: { include_inactive: true }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'pipeline administration' do
    it 'allows an administrator to create and update a pipeline' do
      post base_url, params: { name: 'Sales', active: true }, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      pipeline_id = response.parsed_body.dig('pipeline', 'id')

      patch "#{base_url}/#{pipeline_id}", params: { name: 'Enterprise Sales', active: false }, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(VibeExe::Crm::Pipeline.find(pipeline_id)).to have_attributes(name: 'Enterprise Sales', active: false)
    end

    it 'keeps only one default pipeline when creating or updating defaults' do
      existing = VibeExe::Crm::Pipeline.create!(account: account, name: 'Existing', default: true)

      post base_url, params: { name: 'New default', default: true }, headers: headers, as: :json

      created = VibeExe::Crm::Pipeline.find(response.parsed_body.dig('pipeline', 'id'))
      expect(created).to be_default
      expect(existing.reload).not_to be_default
    end

    it 'rejects pipeline mutation by an agent' do
      post base_url, params: { name: 'Forbidden' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(VibeExe::Crm::Pipeline.find_by(name: 'Forbidden')).to be_nil
    end

    it 'rejects access when CRM is disabled' do
      account.disable_features!(:crm)

      get base_url, headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/vibeexe/crm/pipelines/bootstrap_default' do
    it 'creates the default pipeline and seven stages idempotently' do
      expect do
        2.times { post "#{base_url}/bootstrap_default", headers: headers, as: :json }
      end.to change(VibeExe::Crm::Pipeline, :count).by(1)
        .and change(VibeExe::Crm::PipelineStage, :count).by(7)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('pipeline', 'stages').pluck('name')).to eq(
        ['New', 'Contacted', 'Qualified', 'Viewing', 'Negotiation', 'Won', 'Lost']
      )
    end
  end

  describe 'stage administration' do
    let!(:pipeline) { VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales') }
    let(:stages_url) { "#{base_url}/#{pipeline.id}/stages" }

    it 'creates and updates stage lifecycle fields' do
      post stages_url,
           params: { name: 'Qualified', stage_type: 'open_stage', probability: 30, active: true, default: true },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:created)
      stage_id = response.parsed_body.dig('stage', 'id')
      VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'Open')

      patch "#{stages_url}/#{stage_id}",
            params: { name: 'Closed won', stage_type: 'won_stage', probability: 100, active: false },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:success)
      expect(VibeExe::Crm::PipelineStage.find(stage_id)).to have_attributes(
        name: 'Closed won', stage_type: 'won_stage', probability: 100, active: false, default: true
      )
    end

    it 'keeps only one default start stage' do
      first = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'First', default: true)
      second = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'Second')

      patch "#{stages_url}/#{second.id}", params: { default: true }, headers: headers, as: :json

      expect(second.reload).to be_default
      expect(first.reload).not_to be_default
    end

    it 'reorders every stage atomically' do
      first = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'First', position: 0)
      second = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'Second', position: 1)

      patch "#{stages_url}/reorder", params: { stage_ids: [second.id, first.id] }, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(pipeline.stages.ordered.pluck(:id)).to eq([second.id, first.id])
    end

    it 'rejects incomplete stage orders' do
      first = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'First')
      VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'Second')

      patch "#{stages_url}/reorder", params: { stage_ids: [first.id] }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'prevents removing the last active open stage from an active pipeline' do
      stage = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'Open')

      patch "#{stages_url}/#{stage.id}", params: { active: false }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(stage.reload).to be_active
    end

    it 'prevents deleting a stage used by a lead' do
      stage = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'Used')
      VibeExe::Crm::Lead.create!(account: account, contact: create(:contact, account: account), pipeline: pipeline,
                                 pipeline_stage: stage, title: 'Lead', source: 'manual')

      delete "#{stages_url}/#{stage.id}", headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(VibeExe::Crm::PipelineStage.exists?(stage.id)).to be(true)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/vibeexe/crm/pipelines/:id' do
    it 'prevents deleting a pipeline used by a lead' do
      pipeline = VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales')
      stage = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New')
      VibeExe::Crm::Lead.create!(account: account, contact: create(:contact, account: account), pipeline: pipeline,
                                 pipeline_stage: stage, title: 'Lead', source: 'manual')

      delete "#{base_url}/#{pipeline.id}", headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(VibeExe::Crm::Pipeline.exists?(pipeline.id)).to be(true)
    end
  end
end
