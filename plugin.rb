# frozen_string_literal: true

# name: discourse-marketo
# about: Synchronizes Marketo leads with Discourse users
# version: 0.0.1
# authors: Discourse
# url: https://github.com/discourse/discourse-marketo

enabled_site_setting :discourse_marketo_enabled

require_relative "lib/marketo_api"
require_relative "lib/validators/discourse_marketo_enabled_validator"

after_initialize do
  module ::DiscourseMarketo
    PLUGIN_NAME = "discourse-marketo"
    UPDATES_QUEUE = "marketo_updates"
  end

  require_relative "app/jobs/regular/update_marketo_lead"
  require_relative "app/jobs/scheduled/update_marketo_leads"

  on(:user_created) { |user| Jobs.enqueue_in(5.seconds, :update_marketo_lead, user_id: user.id) }

  on(:user_updated) { |user| Jobs.enqueue_in(5.seconds, :update_marketo_lead, user_id: user.id) }

  on(:user_destroyed) { |user| Jobs.enqueue_in(5.seconds, :update_marketo_lead, user_id: user.id) }

  on(:user_promoted) do |args|
    Discourse.redis.lpush(DiscourseMarketo::UPDATES_QUEUE, args[:user_id])
  end
end
