# frozen_string_literal: true

# name: discourse-marketo
# about: Synchronizes Marketo leads with Discourse users
# version: 0.0.1
# authors: Discourse
# url: https://github.com/discourse-org/discourse-marketo

enabled_site_setting :discourse_marketo_enabled

load File.expand_path('../lib/marketo_api.rb', __FILE__)
load File.expand_path('../lib/validators/discourse_marketo_enabled_validator.rb', __FILE__)

after_initialize do
  module ::DiscourseMarketo
    PLUGIN_NAME = 'discourse-marketo'
    UPDATES_QUEUE = 'marketo_updates'
  end

  load File.expand_path('../app/jobs/regular/update_marketo_lead.rb', __FILE__)
  load File.expand_path('../app/jobs/scheduled/update_marketo_leads.rb', __FILE__)

  on(:user_created) do |user|
    Jobs.enqueue_in(5.seconds, :update_marketo_lead, user_id: user.id)
  end

  on(:user_updated) do |user|
    Jobs.enqueue_in(5.seconds, :update_marketo_lead, user_id: user.id)
  end

  on(:user_destroyed) do |user|
    Jobs.enqueue_in(5.seconds, :update_marketo_lead, user_id: user.id)
  end

  on(:user_promoted) do |args|
    Discourse.redis.lpush(DiscourseMarketo::UPDATES_QUEUE, args[:user_id])
  end
end
