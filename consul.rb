require "net/http"
require "yajl"

Ohai.plugin(:Consul) do
  provides "consul"

  def create_objects
    consul Mash.new
    consul[:agent] = {}
    consul[:catalog] = {
      :service => {},
      :node => {}
    }
    consul[:status] = {}
  end

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
    parse_json response.body
  end

  def parse_json(str)
    json = StringIO.new(str)
    parser = Yajl::Parser.new
    parser.parse(json)
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
    consul[:catalog][:services].keys.each do |service|
      consul[:catalog][:service][service] = get "catalog/service/#{service}"
    end
    consul[:catalog][:nodes].each do |node|
      name = node['Node']
      consul[:catalog][:node][name] = get "catalog/node/#{name}"
    end

    # status
    consul[:status][:leader] = get "status/leader"
    consul[:status][:peers]  = get "status/peers"
  end

end
