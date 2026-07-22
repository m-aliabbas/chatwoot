require 'rails_helper'

RSpec.describe 'VibeExe CRM Lead Productivity API', type: :request do
  let!(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account) }
  let(:pipeline) { VibeExe::Crm::Pipeline.create!(account: account, name: 'Sales') }
  let(:stage) { VibeExe::Crm::PipelineStage.create!(account: account, pipeline: pipeline, name: 'New') }
  let(:lead) do
    VibeExe::Crm::Lead.create!(account: account, contact: contact, pipeline: pipeline, pipeline_stage: stage, title: 'Productive lead', source: 'manual')
  end
  let(:headers) { agent.create_new_auth_token }
  let(:lead_url) { "/api/v1/accounts/#{account.id}/vibeexe/crm/leads/#{lead.id}" }

  before { account.enable_features!(:crm) }

  it 'creates a first-class note with author and activity' do
    expect do
      post "#{lead_url}/notes", params: { body: "First line\nSecond line" }, headers: headers, as: :json
    end.to change(VibeExe::Crm::LeadNote, :count).by(1)
      .and change(VibeExe::Crm::LeadActivity.where(activity_type: 'note_created'), :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig('note', 'author', 'id')).to eq(agent.id)
  end

  it 'prevents another agent from editing the note' do
    note = VibeExe::Crm::LeadNote.create!(account: account, lead: lead, author: admin, body: 'Private context')

    patch "#{lead_url}/notes/#{note.id}", params: { body: 'Changed' }, headers: headers, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(note.reload.body).to eq('Private context')
  end

  it 'adds a shared account label once and filters leads by it' do
    label = account.labels.create!(title: 'hot', color: '#ff0000')

    expect do
      post "#{lead_url}/tags/#{label.id}", headers: headers, as: :json
      post "#{lead_url}/tags/#{label.id}", headers: headers, as: :json
    end.to change { lead.reload.label_list.to_a }.from([]).to(['hot'])

    get "/api/v1/accounts/#{account.id}/vibeexe/crm/leads", params: { label_id: label.id }, headers: headers, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['leads'].pluck('id')).to contain_exactly(lead.id)
    expect(response.parsed_body.dig('summary', 'total_count')).to eq(1)
    expect(response.parsed_body.dig('summary', 'stage_counts', stage.id.to_s)).to eq(1)
  end

  it 'rejects a label from another account without leaking it' do
    other_label = create(:account).labels.create!(title: 'private')

    post "#{lead_url}/tags/#{other_label.id}", headers: headers, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
