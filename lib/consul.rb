require "net/http"
require "yajl"

module Ohai
  module Plugin
    module Consul
      CONSUL_API_VERSION = "v1"
      CONSUL_API_HOST = "127.0.0.1"
      CONSUL_API_PORT = 8500

      def http_client
        Net::HTTP.start(CONSUL_API_HOST, CONSUL_API_PORT)
      end

      def get(key)
        Ohai::Log.debug("get from consul api /#{CONSUL_API_VERSION}/#{key}")
        response = http_client.get("/#{CONSUL_API_VERSION}/#{key}")
        unless response.code == '200'
          raise "Encountered error retrieving consul API (returned #{response.code} response)"
        end
        Yajl::Parser.new.parse(response.body)
      end

      class ServiceHash < Hash
        include Ohai::Plugin::Consul
        def [](name)
          v = fetch(name){|n| get("catalog/service/#{n}")}
          store(name, v)
        end
      end

      class NodeHash < Hash
        include Ohai::Plugin::Consul
        def [](name)
          v = fetch(name){|n| get("catalog/node/#{n}")}
          store(name, v)
        end
      end

    end
  end
end

Ohai.plugin(:Consul) do
  provides "consul"
  include Ohai::Plugin::Consul

  def create_objects
    consul Mash.new
    consul[:agent] = {}
    consul[:catalog] = {
      :service => {},
      :node => {}
    }
    consul[:status] = {}
  end

  collect_data(:default) do
    create_objects

    # agent
    [ :checks, :members, :services ].each do |key|
      consul[:agent][key] = get "agent/#{key}"
    end

    # catalog
    [ :datacenters, :nodes, :services ].each do |key|
      consul[:catalog][key] = get "catalog/#{key}"
    end

    # collect all services
    consul[:catalog][:services].keys.each do |name|
      consul[:catalog][:service][name] = get "catalog/service/#{name}"
    end

    # collect all nodes
    consul[:catalog][:nodes].map{|n| n["Node"]}.each do |name|
      consul[:catalog][:node][name] = get "catalog/node/#{name}"
    end

    # status
    consul[:status][:leader] = get "status/leader"
    consul[:status][:peers]  = get "status/peers"
  end

end
