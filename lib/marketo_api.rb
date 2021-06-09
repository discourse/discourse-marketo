# frozen_string_literal: true

require 'net/http'

class MarketoApi
  def leads(params)
    api_response { get('v1/leads.json', params: params) }
  end

  def update_leads(action: 'updateOnly', lookupField: 'email', input: [])
    api_response do
      post('v1/leads.json', data: {
        action: action,
        lookupField: lookupField,
        input: input
      })
    end
  end

  def delete_leads(ids: [])
    api_response do
      post('v1/leads/delete.json', data: {
        input: ids.map { |id| { id: id } }
      })
    end
  end

  private

  def access_token
    if @access_token && @expires_at && @expires_at > Time.zone.now
      return @access_token
    end

    Rails.logger.debug('[MarketoApi] Fetching new access token')
    now = Time.zone.now

    uri = URI.parse("#{SiteSetting.marketo_identity}/oauth/token" +
                    "?grant_type=client_credentials" +
                    "&client_id=#{SiteSetting.marketo_client_id}" +
                    "&client_secret=#{SiteSetting.marketo_client_secret}")
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    response = http(uri).request(request)
    json = JSON.parse(response.body)

    @expires_at = now + json['expires_in'].seconds
    @access_token = json['access_token']
  end

  def api_response
    request = yield

    if request.body.blank?
      Rails.logger.warn("[MarketoApi] API returned empty response")
      return
    end

    begin
      response = JSON.parse(request.body)
    rescue JSON::Error => e
      Rails.logger.warn("[MarketoApi] API returned invalid JSON response: #{e.message}, body = #{response.body}")
      return
    end

    if !response["success"]
      Rails.logger.warn("[MarketoApi] API call failed: #{response['errors']}")
      return
    end

    response
  end

  def get(endpoint, params: {})
    Rails.logger.debug("[MarketoApi] Requesting GET #{endpoint} with params = #{params}")

    query_string = params.map { |k, v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&')
    uri = URI.parse("#{SiteSetting.marketo_endpoint}/#{endpoint}?access_token=#{access_token}&#{query_string}")

    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    http(uri).request(request)
  end

  def post(endpoint, data: {})
    Rails.logger.debug("[MarketoApi] Requesting POST #{endpoint} with data = #{data}")

    uri = URI.parse("#{SiteSetting.marketo_endpoint}/#{endpoint}?access_token=#{access_token}")

    request = Net::HTTP::Post.new(uri)
    request['Accept'] = request['Content-Type'] = 'application/json'
    request.body = data.to_json
    http(uri).request(request)
  end

  def http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.port == 443
    http
  end
end
