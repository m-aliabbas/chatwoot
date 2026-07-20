require 'rails_helper'

RSpec.describe 'Super Admin branding', type: :request do
  let(:super_admin) { create(:super_admin) }

  it 'renders configured visual branding in the super admin shell' do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('INSTALLATION_NAME', 'Chatwoot').and_return('VibeDesk')
    allow(GlobalConfigService).to receive(:load).with('LOGO_THUMBNAIL', '/brand-assets/logo_thumbnail.svg').and_return('/custom/logo-thumb.svg')

    sign_in(super_admin, scope: :super_admin)
    get '/super_admin/users'

    expect(response).to have_http_status(:success)
    expect(response.body).to include('<title>')
    expect(response.body).to include('VibeDesk Super Admin')
    expect(response.body).to include('src="/custom/logo-thumb.svg"', 'alt="VibeDesk Admin Dashboard"')
    expect(response.body).to include("VibeDesk #{Chatwoot.config[:version]}")
  end
end
