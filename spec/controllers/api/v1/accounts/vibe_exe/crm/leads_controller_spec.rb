require 'rails_helper'

RSpec.describe 'VibeExe CRM Leads API', type: :request do
  let!(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:contact) { create(:contact, account: account, name: 'Ava Buyer', email: 'ava@example.com') }
  let(:pipeline) { VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales', default: true) }
  let!(:stage) { VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New', default: true) }
  let(:headers) { admin.create_new_auth_token }
  let(:base_url) { "/api/v1/accounts/#{account.id}/vibeexe/crm/leads" }

  before do
    account.enable_features!(:crm)
  end

  describe 'GET /api/v1/accounts/:account_id/vibeexe/crm/leads' do
    it 'returns only account-scoped leads with search and pagination metadata' do
      lead = VibeExe::Crm::Lead.create!(
        account: account,
        contact: contact,
        pipeline: pipeline,
        pipeline_stage: stage,
        title: 'Downtown apartment',
        source: 'manual'
      )
      other_account = create(:account)
      other_pipeline = VibeExe::Crm::Pipeline.create!(account: other_account, name: 'Sales')
      other_stage = VibeExe::Crm::PipelineStage.create!(account: other_account, pipeline: other_pipeline, name: 'New')
      VibeExe::Crm::Lead.create!(
        account: other_account,
        contact: create(:contact, account: other_account),
        pipeline: other_pipeline,
        pipeline_stage: other_stage,
        title: 'Downtown apartment',
        source: 'manual'
      )

      get base_url, params: { q: 'Downtown', page: 1 }, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['leads'].pluck('id')).to eq([lead.id])
      expect(response.parsed_body.dig('meta', 'total_count')).to eq(1)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/vibeexe/crm/leads' do
    it 'creates a manual lead and records activity' do
      expect do
        post base_url,
             params: {
               contact_id: contact.id,
               title: 'Manual lead',
               pipeline_id: pipeline.id,
               pipeline_stage_id: stage.id,
               source: 'manual',
               estimated_value: '120000.25',
               currency: 'USD'
             },
             headers: headers,
             as: :json
      end.to change(VibeExe::Crm::Lead, :count).by(1)
        .and change(VibeExe::Crm::LeadActivity, :count).by(1)

      expect(response).to have_http_status(:created), response.body
      expect(response.parsed_body.dig('lead', 'estimated_value')).to eq('120000.25')
    end

    it 'rejects cross-account contact ids' do
      other_contact = create(:contact)

      post base_url,
           params: {
             contact_id: other_contact.id,
             title: 'Invalid lead',
             pipeline_id: pipeline.id,
             pipeline_stage_id: stage.id,
             source: 'manual'
           },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH lifecycle actions' do
    let!(:lead) do
      VibeExe::Crm::Lead.create!(
        account: account,
        contact: contact,
        pipeline: pipeline,
        pipeline_stage: stage,
        title: 'Lifecycle lead',
        source: 'manual'
      )
    end

    it 'marks a lead won with activity' do
      expect do
        patch "#{base_url}/#{lead.id}/mark_won", headers: headers, as: :json
      end.to change(VibeExe::Crm::LeadActivity, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(lead.reload).to be_won
      expect(lead.closed_status).to eq('won')
    end

    it 'archives a lead without deleting it' do
      patch "#{base_url}/#{lead.id}/archive", headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(lead.reload.archived_at).to be_present
    end
  end
end
