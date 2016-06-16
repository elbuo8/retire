require 'uri'
require 'aws-sdk'
require 'faraday'
require 'faraday_middleware'
require 'faraday_middleware/aws_signers_v4'
# A Faraday-based HTTP client, which allows you to choose a HTTP client.
#
# See <https://github.com/technoweenie/faraday/tree/master/lib/faraday/adapter>
#
# NOTE: Tire will switch to Faraday for the HTTP abstraction layer. This client is a temporary solution.
#
# Example:
# --------
#
#     require 'typhoeus'
#     require 'tire/http/clients/faraday'
#
#     Tire.configure do |config|
#
#       # Unless specified, tire will use Faraday.default_adapter and no middleware
#       Tire::HTTP::Client::Faraday.faraday_middleware = Proc.new do |builder|
#         builder.adapter :typhoeus
#       end
#
#       config.client(Tire::HTTP::Client::Faraday)
#
#     end
#
#
module Tire
  module HTTP
    module Client
      class Faraday

        # Default middleware stack.
        DEFAULT_MIDDLEWARE = Proc.new do |builder|
          builder.adapter ::Faraday.default_adapter
        end

        class << self
          # A customized stack of Faraday middleware that will be used to make each request.
          attr_accessor :faraday_middleware

          def get(url, data = nil)
            request(:get, url, data)
          end

          def post(url, data)
            result = request(:post, url, data)

            if Configuration.replica_url
              replica_url = url.gsub(Configuration.url, Configuration.replica_url)
              request(:post, replica_url, data)
            end

            result
          end

          def put(url, data)
            result = request(:put, url, data)
            if Configuration.replica_url
              replica_url = url.gsub(Configuration.url, Configuration.replica_url)
              request(:put, replica_url, data)
            end

            result
          end

          def delete(url, data = nil)
            result = request(:delete, url, data)

            if Configuration.replica_url
              replica_url = url.gsub(Configuration.url, Configuration.replica_url)
              request(:delete, replica_url, data)
            end

            result
          end

          def head(url)
            request(:head, url)
          end

          def __host_unreachable_exceptions
            [::Faraday::Error::ConnectionFailed, ::Faraday::Error::TimeoutError]
          end

          private
          def request(method, url, data = nil)
            parsed_url = URI(url)
            conn = ::Faraday.new do |faraday|
              faraday.request :basic_auth, parsed_url.user, parsed_url.password
              faraday.adapter ::Faraday.default_adapter
            end

            if url.include? 'es.amazonaws.com'
              conn = ::Faraday.new do |faraday|
                faraday.request :aws_signers_v4,
                  credentials: Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID'), ENV.fetch('AWS_SECRET_ACCESS_KEY')),
                  service_name: 'es',
                  region: ENV.fetch('AWS_REGION')

                faraday.adapter ::Faraday.default_adapter
              end
            end
            response = conn.run_request(method, url, data, nil)
            Response.new(response.body, response.status, response.headers)
          end
        end
      end
    end
  end
end
