# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "net/http"

# Provides the {Eth} module.
module Eth

  # Provides an HTTP/S-RPC client.
  class Client::Http < Client

    # The host of the HTTP endpoint.
    attr_reader :host

    # The port of the HTTP endpoint.
    attr_reader :port

    # The full URI of the HTTP endpoint, including path.
    attr_reader :uri

    # Attribute indicator for SSL.
    attr_reader :ssl

    # Constructor for the HTTP Client. Should not be used; use
    # {Client.create} intead.
    #
    # @param host [String] an URI pointing to an HTTP RPC-API.
    def initialize(host, proxy = nil)
      super
      uri = URI.parse(host)
      raise ArgumentError, "Unable to parse the HTTP-URI!" unless ["http", "https"].include? uri.scheme
      @host = uri.host
      @port = uri.port
      @ssl = uri.scheme == "https"
      @uri = URI("#{uri.scheme}://#{@host}:#{@port}#{uri.path}")
      @proxy = proxy
    end

    # Sends an RPC request to the connected HTTP client.
    #
    # @param payload [Hash] the RPC request parameters.
    # @return [String] a JSON-encoded response.
    def send(payload)
      if @proxy.present?
        proxy_info = Net::HTTP::Proxy(@proxy[:host].split(':')[0], @proxy[:host].split(':')[1], @proxy[:username], @proxy[:password])
        http = Net::HTTP.new(@host, @port)
        http.use_ssl = @ssl
        header = { "Content-Type" => "application/json"}
        # header = { "Content-Type" => "application/json", "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/109.0"}
        request = Net::HTTP::Post.new(@uri, header)
        request.basic_auth(@proxy[:username], @proxy[:password])
        request.body = payload
        response = proxy_info.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(request)
        end
        response.body
      else
        http = Net::HTTP.new(@host, @port)
        http.use_ssl = @ssl
        header = { "Content-Type" => "application/json"}
        # header = { "Content-Type" => "application/json", "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/109.0"}
        request = Net::HTTP::Post.new(@uri, header)
        request.body = payload
        response = http.request(request)
        response.body
      end
    end
  end
end
