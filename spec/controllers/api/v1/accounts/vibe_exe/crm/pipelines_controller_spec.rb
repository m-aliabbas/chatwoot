require 'rails_helper'

RSpec.describe 'VibeExe CRM Pipelines API', type: :request do
  let!(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let(:base_url) { "/api/v1/accounts/#{account.id}/vibeexe/crm/pipelines" }

  before do
    account.enable_features!(:crm)
  end

  describe 'POST /api/v1/accounts/:account_id/vibeexe/crm/pipelines/bootstrap_default' do
    it 'creates the default pipeline idempotently' do
      expect do
        2.times { post "#{base_url}/bootstrap_default", headers: headers, as: :json }
      end.to change(VibeExe::Crm::Pipeline, :count).by(1)
        .and change(VibeExe::Crm::PipelineStage, :count).by(7)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('pipeline', 'stages').pluck('name')).to include('New', 'Won', 'Lost')
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/vibeexe/crm/pipelines/:id' do
    it 'prevents deleting a pipeline used by a lead' do
      pipeline = VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales')
      stage = VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New')
      VibeExe::Crm::Lead.create!(
        account: account,
        contact: create(:contact, account: account),
        pipeline: pipeline,
        pipeline_stage: stage,
        title: 'Used pipeline lead',
        source: 'manual'
      )

      delete "#{base_url}/#{pipeline.id}", headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(VibeExe::Crm::Pipeline.exists?(pipeline.id)).to be(true)
    end
  end
end
