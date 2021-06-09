# frozen_string_literal: true

module Jobs
  class UpdateMarketoLead < ::Jobs::Base
    def execute(args)
      user = User.find_by(id: args[:user_id])
      return if user.blank?

      api = MarketoApi.new

      newsletter_field_id = UserField.where(name: SiteSetting.marketo_newsletter_field)&.first&.id
      if user.user_fields[newsletter_field_id.to_s].present?
        response = api.update_leads(
          action: 'createOrUpdate',
          input: [{
            email: user.email,
            SiteSetting.marketo_trust_level_field => user.trust_level,
          }]
        )

        response["result"].each do |result|
          if result["status"] == "skipped"
            Rails.logger.warn("Skipped lead update for user #{user.id}: #{result["reasons"]}")
          end
        end
      else
        if leads = api.leads(filterType: 'email', filterValues: user.emails.join(','))
          lead_ids = leads['result'].map { |lead| lead['id'] }
          api.delete_leads(ids: lead_ids)
        end
      end
    end
  end
end
