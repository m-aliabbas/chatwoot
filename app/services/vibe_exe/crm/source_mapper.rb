class VibeExe::Crm::SourceMapper
  pattr_initialize [:inbox!]

  CHANNEL_SOURCES = {
    'Channel::Api' => 'api',
    'Channel::Email' => 'email',
    'Channel::FacebookPage' => 'facebook',
    'Channel::Instagram' => 'instagram',
    'Channel::Line' => 'line',
    'Channel::Sms' => 'sms',
    'Channel::Telegram' => 'telegram',
    'Channel::TwilioSms' => 'twilio',
    'Channel::TwitterProfile' => 'twitter',
    'Channel::WebWidget' => 'website',
    'Channel::Whatsapp' => 'whatsapp'
  }.freeze

  def perform
    return 'whatsapp' if inbox.channel_type == 'Channel::TwilioSms' && inbox.medium == 'whatsapp'
    return 'sms' if inbox.channel_type == 'Channel::TwilioSms' && inbox.medium == 'sms'

    CHANNEL_SOURCES.fetch(inbox.channel_type, 'inbox')
  end
end
