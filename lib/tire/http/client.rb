module Tire

  module HTTP

    module Client

      class RestClient
        ConnectionExceptions = [::RestClient::ServerBrokeConnection, ::RestClient::RequestTimeout]

        def self.get(url, data=nil)
          perform ::RestClient::Request.new(:method => :get, :url => url, :payload => data).execute
        rescue *ConnectionExceptions
          raise
        rescue ::RestClient::Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.post(url, data)
          result = perform ::RestClient.post(url, data)
          if !Configuration.replica_url.nil?
            replica_url = url.gsub(Configuration.url, Configuration.replica_url)
            perform ::RestClient.post(replica_url, data)
          end
          result
        rescue *ConnectionExceptions
          raise
        rescue ::RestClient::Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.put(url, data)
          replica_url = url.gsub(Configuration.url, Configuration.replica_url)
          result = perform ::RestClient.put(url, data)
          if !Configuration.replica_url.nil?
            replica_url = url.gsub(Configuration.url, Configuration.replica_url)
            perform ::RestClient.put(replica_url, data)
          end
          result
        rescue *ConnectionExceptions
          raise
        rescue ::RestClient::Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.delete(url)
          result = perform ::RestClient.delete(url)
          if !Configuration.replica_url.nil?
            replica_url = url.gsub(Configuration.url, Configuration.replica_url)
            perform ::RestClient.delete(replica_url)
          end
          result
        rescue *ConnectionExceptions
          raise
        rescue ::RestClient::Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.head(url)
          perform ::RestClient.head(url)
        rescue *ConnectionExceptions
          raise
        rescue ::RestClient::Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.__host_unreachable_exceptions
          [Errno::ECONNREFUSED, Errno::ETIMEDOUT, ::RestClient::ServerBrokeConnection, ::RestClient::RequestTimeout, SocketError]
        end

        private

        def self.perform(response)
          Response.new response.body, response.code, response.headers
        end

      end

    end

  end

end
