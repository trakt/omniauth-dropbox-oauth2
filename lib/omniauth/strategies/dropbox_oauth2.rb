require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class DropboxOauth2 < OmniAuth::Strategies::OAuth2
      option :name, 'dropbox_oauth2'      
      option :client_options,
             site: 'https://api.dropbox.com',
             authorize_url: 'https://www.dropbox.com/oauth2/authorize',
             token_url: 'https://api.dropbox.com/oauth2/token'
      option :authorize_params,
             token_access_type: 'offline',

      uid { raw_info['uid'] }

      info do
        {
          'uid'   => raw_info['account_id'],
          'name'  => raw_info['name']['display_name'],
          'email' => raw_info['email']
        }
      end

      extra do
        { 'raw_info' => raw_info }
      end

      def raw_info
        conn = Faraday.new(:url => 'https://api.dropbox.com') do |faraday|
          faraday.request  :url_encoded             # form-encode POST params
          faraday.response :logger                  # log requests to STDOUT
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end
        response = conn.post do |req|
          req.url '/2/users/get_current_account'
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{access_token.token}"
          req.body = "null"
        end
        @raw_info ||= MultiJson.decode(response.body)
        # @raw_info ||= MultiJson.decode(access_token.get('/2/users/get_current_account').body)
      end
      
      def callback_url_without_query_string
         full_host + script_name + callback_path
       end

      def callback_url
        if @authorization_code_from_signed_request
          ''
        else
          options[:callback_url] || callback_url_without_query_string
        end
      end
    end
  end
end
