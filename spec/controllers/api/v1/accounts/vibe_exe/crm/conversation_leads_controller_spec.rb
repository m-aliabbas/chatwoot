require 'rails_helper'

RSpec.describe 'VibeExe CRM Conversation Leads API', type: :request do
  let!(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:pipeline) { VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales', default: true) }
  let!(:stage) { VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New', default: true) }
  let(:headers) { admin.create_new_auth_token }
  let(:base_url) do
    "/api/v1/accounts/#{account.id}/vibeexe/crm/conversations/#{conversation.display_id}/leads"
  end

  before do
    account.enable_features!(:crm)
    VibeExe::Crm::InboxLeadConfig.create!(
      account: account,
      inbox: inbox,
      lead_creation_mode: :manual,
      default_pipeline: pipeline
    )
  end

  describe 'routing' do
    it 'uses conversation_id as the canonical route parameter' do
      route = Rails.application.routes.recognize_path(base_url, method: :post)

      expect(route[:conversation_id]).to eq(conversation.display_id.to_s)
      expect(route).not_to have_key(:conversation_conversation_id)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/vibeexe/crm/conversations/:conversation_id/leads' do
    it 'returns linked lead data for a valid conversation' do
      get base_url, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['leads']).to eq([])
      expect(response.parsed_body['lead_creation_mode']).to eq('manual')
    end

    it 'returns not found for a missing conversation' do
      get "/api/v1/accounts/#{account.id}/vibeexe/crm/conversations/999999/leads",
          headers: headers,
          as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a cross-account conversation' do
      other_account = create(:account)
      other_conversation = create(:conversation, account: other_account)
      other_conversation.update!(display_id: 99_999)

      get "/api/v1/accounts/#{account.id}/vibeexe/crm/conversations/#{other_conversation.display_id}/leads",
          headers: headers,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/vibeexe/crm/conversations/:conversation_id/leads' do
    it 'creates a lead from the conversation' do
      expect do
        post base_url, headers: headers, as: :json
      end.to change(VibeExe::Crm::Lead, :count).by(1)
        .and change(VibeExe::Crm::LeadConversation, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['lead']['pipeline_id']).to eq(pipeline.id)
      expect(response.parsed_body['linked_leads'].size).to eq(1)
    end

    it 'uses the conversation inbox while resolving config' do
      post base_url, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(VibeExe::Crm::Lead.last.metadata['inbox_id']).to eq(inbox.id)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/vibeexe/crm/conversations/:conversation_id/leads/link' do
    it 'links an existing lead to the conversation' do
      lead = VibeExe::Crm::Lead.create!(
        account: account,
        contact: conversation.contact,
        pipeline: pipeline,
        pipeline_stage: stage,
        title: 'Existing lead',
        source: 'website'
      )

      post "#{base_url}/link",
           params: { lead_id: lead.id },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:success), response.body
      expect(VibeExe::Crm::LeadConversation.find_by(lead: lead, conversation: conversation)).to be_present
      expect(response.parsed_body['linked_leads'].first['id']).to eq(lead.id)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/vibeexe/crm/conversations/:conversation_id/leads/:id/unlink' do
    it 'unlinks an existing lead from the conversation' do
      lead = VibeExe::Crm::Lead.create!(
        account: account,
        contact: conversation.contact,
        pipeline: pipeline,
        pipeline_stage: stage,
        title: 'Existing lead',
        source: 'website'
      )
      VibeExe::Crm::LeadConversation.create!(
        account: account,
        lead: lead,
        conversation: conversation,
        source: 'manual'
      )

      expect do
        delete "#{base_url}/#{lead.id}/unlink", headers: headers, as: :json
      end.to change(VibeExe::Crm::LeadConversation, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['linked_leads']).to eq([])
    end
  end
end
