module BrandingHelper
  DEFAULT_INSTALLATION_NAME = 'Chatwoot'.freeze
  DEFAULT_LOGO = '/brand-assets/logo.svg'.freeze
  DEFAULT_LOGO_DARK = '/brand-assets/logo_dark.svg'.freeze
  DEFAULT_LOGO_THUMBNAIL = '/brand-assets/logo_thumbnail.svg'.freeze

  def brand_installation_name
    GlobalConfigService.load('INSTALLATION_NAME', DEFAULT_INSTALLATION_NAME).presence || DEFAULT_INSTALLATION_NAME
  end

  def brand_logo
    GlobalConfigService.load('LOGO', DEFAULT_LOGO).presence || DEFAULT_LOGO
  end

  def brand_logo_dark
    GlobalConfigService.load('LOGO_DARK', DEFAULT_LOGO_DARK).presence || DEFAULT_LOGO_DARK
  end

  def brand_logo_thumbnail
    GlobalConfigService.load('LOGO_THUMBNAIL', DEFAULT_LOGO_THUMBNAIL).presence || DEFAULT_LOGO_THUMBNAIL
  end
end
