require "test/unit"
require "ohai"
require "tmpdir"
require "glint"

class TestOhaiPluginConsul < Test::Unit::TestCase
  def setup
    server = Glint::Server.new(8500, { :timeout => 3 }) do |port|
      dir = Dir.tmpdir
      exec "consul", "agent", "-data-dir", dir, "-server", "-bootstrap"
    end
    server.start

    Ohai::Config[:plugin_path] << "./lib"
    @o = Ohai::System.new
  end

  def test_consul
    @o.all_plugins
    consul = @o[:consul]
    assert_not_nil consul

    # agent
    assert_equal({}, consul[:agent][:checks])
    assert_equal 1, consul[:agent][:members].size

    # catalog
    assert_equal(["dc1"], consul[:catalog][:datacenters])
    assert_equal(1, consul[:catalog][:nodes].size)
    node_name = consul[:catalog][:nodes][0]["Node"]
    assert_not_nil consul[:catalog][:node][node_name]

    assert_equal({"consul" => nil}, consul[:catalog][:services])
    assert_not_nil consul[:catalog][:service]["consul"]

    # status
    assert_not_nil consul[:status][:leader]
    assert_not_nil consul[:status][:peers]

    puts consul
  end
end
