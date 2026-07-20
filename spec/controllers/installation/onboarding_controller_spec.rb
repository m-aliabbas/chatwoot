require 'rails_helper'

RSpec.describe 'Installation::Onboarding API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /installation/onboarding' do
    context 'when CHATWOOT_INSTALLATION_ONBOARDING redis key is not set' do
      it 'redirects back' do
        expect(Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)).to be_nil
        get '/installation/onboarding'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when CHATWOOT_INSTALLATION_ONBOARDING redis key is set' do
      it 'returns onboarding page' do
        Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
        get '/installation/onboarding'
        expect(response).to have_http_status(:success)
        Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
      end

      it 'renders configured visual branding on the onboarding page' do
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('INSTALLATION_NAME', 'Chatwoot').and_return('VibeDesk')
        allow(GlobalConfigService).to receive(:load).with('LOGO', '/brand-assets/logo.svg').and_return('/custom/logo.svg')
        allow(GlobalConfigService).to receive(:load).with('LOGO_DARK', '/brand-assets/logo_dark.svg').and_return('/custom/logo-dark.svg')

        Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
        get '/installation/onboarding'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('<title>SuperAdmin | VibeDesk</title>')
        expect(response.body).to include('src="/custom/logo.svg"', 'src="/custom/logo-dark.svg"', 'alt="VibeDesk"')
        expect(response.body).to include('Howdy, Welcome to VibeDesk')
        Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
      end
    end
  end

  describe 'POST /installation/onboarding' do
    let(:account_builder) { double }

    before do
      allow(AccountBuilder).to receive(:new).and_return(account_builder)
      allow(account_builder).to receive(:perform).and_return(true)
      allow(ChatwootHub).to receive(:register_instance).and_return(true)
      Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
    end

    after do
      Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
    end

    context 'when onboarding successfull' do
      it 'deletes the redis key' do
        post '/installation/onboarding', params: { user: {} }
        expect(Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)).to be_nil
      end

      it 'will not call register instance when checkboxes are unchecked' do
        post '/installation/onboarding', params: { user: {} }
        expect(ChatwootHub).not_to have_received(:register_instance)
      end

      it 'will call register instance when checkboxes are checked' do
        post '/installation/onboarding', params: { user: {}, subscribe_to_updates: 1 }
        expect(ChatwootHub).to have_received(:register_instance)
      end
    end

    context 'when onboarding is not successfull' do
      it 'does not deletes the redis key' do
        allow(AccountBuilder).to receive(:new).and_raise('error')
        post '/installation/onboarding', params: { user: {} }
        expect(Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)).not_to be_nil
      end
    end
  end
end
