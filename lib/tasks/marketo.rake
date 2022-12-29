# frozen_string_literal: true

task "marketo:update_all" => :environment do
  api = MarketoApi.new
  newsletter_field_id = UserField.where(name: SiteSetting.marketo_newsletter_field)&.first&.id

  User
    .includes(:primary_email)
    .joins(:_custom_fields)
    .where(user_custom_fields: { name: "#{User::USER_FIELD_PREFIX}#{newsletter_field_id}" })
    .where(user_custom_fields: { value: "true" })
    .in_batches(of: SiteSetting.marketo_updates_size) do |relation|
      input =
        relation
          .pluck(:email, :trust_level)
          .map do |email, trust_level|
            { :email => email, SiteSetting.marketo_trust_level_field => trust_level }
          end

      api.update_leads(action: "createOrUpdate", input: input)
    end
end
