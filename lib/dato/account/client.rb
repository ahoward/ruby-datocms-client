# frozen_string_literal: true
require 'faraday'
require 'faraday_middleware'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'

require 'dato/version'

require 'dato/account/repo/account'
require 'dato/account/repo/site'
require 'dato/api_error'

module Dato
  module Account
    class Client
      REPOS = {
        account: Repo::Account,
        sites: Repo::Site
      }.freeze

      attr_reader :token, :base_url, :schema, :extra_headers

      def initialize(
        token,
        base_url: 'https://account-api.datocms.com',
        extra_headers: {}
      )
        @base_url = base_url
        @token = token
        @extra_headers = extra_headers
      end

      REPOS.each do |method_name, repo_klass|
        define_method method_name do
          instance_variable_set(
            "@#{method_name}",
            instance_variable_get("@#{method_name}") ||
            repo_klass.new(self)
          )
        end
      end

      def request(*args)
        connection.send(*args).body.with_indifferent_access
      rescue Faraday::ConnectionFailed => e
        raise e
      rescue Faraday::ClientError => e
        raise ApiError, e
      end

      private

      def connection
        options = {
          url: base_url,
          headers: extra_headers.merge(
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@token}",
            'User-Agent' => "ruby-client v#{Dato::VERSION}"
          )
        }

        @connection ||= Faraday.new(options) do |c|
          c.request :json
          c.response :json, content_type: /\bjson$/
          c.response :raise_error
          c.use FaradayMiddleware::FollowRedirects
          c.adapter :net_http
        end
      end
    end
  end
end
