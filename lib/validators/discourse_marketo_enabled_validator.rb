# frozen_string_literal: true

class DiscourseMarketoEnabledValidator
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(val)
    !val || (
      SiteSetting.marketo_endpoint.present? &&
      SiteSetting.marketo_identity.present? &&
      SiteSetting.marketo_client_id.present? &&
      SiteSetting.marketo_client_secret.present?
    )
  end

  def error_message
    I18n.t('site_settings.errors.discourse_marketo_settings_are_empty')
  end
end
