require 'rails_helper'

RSpec.describe 'Super Admin', type: :request do
  describe '/super_admin' do
    it 'renders the login page' do
      with_modified_env LOGRAGE_ENABLED: 'true' do
        get '/super_admin/sign_in'
        expect(response).to have_http_status(:ok)
      end
    end

    it 'renders configured visual branding on the login page' do
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('INSTALLATION_NAME', 'Chatwoot').and_return('VibeDesk')
      allow(GlobalConfigService).to receive(:load).with('LOGO', '/brand-assets/logo.svg').and_return('/custom/logo.svg')
      allow(GlobalConfigService).to receive(:load).with('LOGO_DARK', '/brand-assets/logo_dark.svg').and_return('/custom/logo-dark.svg')

      get '/super_admin/sign_in'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<title>SuperAdmin | VibeDesk</title>')
      expect(response.body).to include('src="/custom/logo.svg"', 'src="/custom/logo-dark.svg"', 'alt="VibeDesk"')
    end
  end
end
