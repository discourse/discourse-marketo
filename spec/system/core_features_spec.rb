# frozen_string_literal: true

RSpec.describe "Core features", type: :system do
  before do
    SiteSetting.marketo_endpoint = "localhost"
    SiteSetting.marketo_identity = "ID"
    SiteSetting.marketo_client_id = "client_id"
    SiteSetting.marketo_client_secret = "client_secret"
    enable_current_plugin
  end

  it_behaves_like "having working core features"
end
