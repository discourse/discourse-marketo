# frozen_string_literal: true

module Jobs
  class UpdateMarketoLeads < ::Jobs::Scheduled
    every 5.minutes

    def execute(args)
      return if !SiteSetting.discourse_marketo_enabled

      queue_size = Discourse.redis.llen(DiscourseMarketo::UPDATES_QUEUE)
      if queue_size > SiteSetting.marketo_updates_size
        Rails.logger.warn(
          "[UpdateMarketoLeads] Marketo user updates may be stuck in queue (current queue size = #{queue_size})",
        )
      end

      user_ids = []
      SiteSetting.marketo_updates_size.times.each do
        user_id = Discourse.redis.rpop(DiscourseMarketo::UPDATES_QUEUE)
        break if user_id.blank?
        user_ids << user_id
      end

      return if user_ids.blank?

      input =
        User
          .includes(:primary_email)
          .where(id: user_ids)
          .pluck(:email, :trust_level)
          .map do |email, trust_level|
            { :email => email, SiteSetting.marketo_trust_level_field => trust_level }
          end

      api = MarketoApi.new
      response = api.update_leads(input: input)

      if !response
        user_ids.each { |user_id| Discourse.redis.lpush(DiscourseMarketo::UPDATES_QUEUE, user_id) }
      end
    end
  end
end
