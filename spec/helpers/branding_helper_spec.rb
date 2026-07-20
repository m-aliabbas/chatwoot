require 'rails_helper'

RSpec.describe BrandingHelper, type: :helper do
  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
  end

  it 'reads visual branding values from GlobalConfigService' do
    allow(GlobalConfigService).to receive(:load).with('INSTALLATION_NAME', 'Chatwoot').and_return('VibeDesk')
    allow(GlobalConfigService).to receive(:load).with('LOGO', '/brand-assets/logo.svg').and_return('/custom/logo.svg')
    allow(GlobalConfigService).to receive(:load).with('LOGO_DARK', '/brand-assets/logo_dark.svg').and_return('/custom/logo-dark.svg')
    allow(GlobalConfigService).to receive(:load).with('LOGO_THUMBNAIL', '/brand-assets/logo_thumbnail.svg').and_return('/custom/logo-thumb.svg')

    expect(helper.brand_installation_name).to eq('VibeDesk')
    expect(helper.brand_logo).to eq('/custom/logo.svg')
    expect(helper.brand_logo_dark).to eq('/custom/logo-dark.svg')
    expect(helper.brand_logo_thumbnail).to eq('/custom/logo-thumb.svg')
  end

  it 'falls back to Chatwoot visual branding when config values are blank' do
    allow(GlobalConfigService).to receive(:load).and_return('')

    expect(helper.brand_installation_name).to eq('Chatwoot')
    expect(helper.brand_logo).to eq('/brand-assets/logo.svg')
    expect(helper.brand_logo_dark).to eq('/brand-assets/logo_dark.svg')
    expect(helper.brand_logo_thumbnail).to eq('/brand-assets/logo_thumbnail.svg')
  end
end
