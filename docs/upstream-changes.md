# Upstream Chatwoot Changes

Record every meaningful modification to an existing upstream Chatwoot file.

| Date | Upstream path | VibeExe purpose | Risk | Tests | Upgrade notes |
|---|---|---|---|---|---|
| YYYY-MM-DD | `path/to/file` | Description | Low/Medium/High | Commands | Merge considerations |
| 2026-07-20 | `config/installation_config.yml`, `enterprise/config/premium_installation_config.yml`, `public/manifest.json`, `public/browserconfig.xml`, `app/mailers/application_mailer.rb`, `app/mailers/conversation_reply_mailer.rb`, `app/models/concerns/email_address_parseable.rb`, `app/presenters/mail_presenter.rb`, `config/initializers/devise.rb`, `app/views/devise/mailer/confirmation_instructions.html.erb`, `enterprise/app/views/devise/mailer/confirmation_instructions.html.erb`, `app/views/layouts/mailer/base.liquid` | Set VibeExe as the default user-facing installation/brand identity while preserving Chatwoot technical identifiers. | Medium | `bundle exec rspec spec/lib/config_loader_spec.rb spec/enterprise/services/internal/reconcile_plan_config_service_spec.rb spec/mailers/confirmation_instructions_spec.rb` | Uses existing config keys and additive assets. Keep upstream package names, APIs, database keys, headers, licenses, and cloud/internal constants unchanged. |
