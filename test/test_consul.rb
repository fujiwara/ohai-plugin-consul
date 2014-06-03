require "test/unit"
require "ohai"
require "tmpdir"
require "glint"

Ohai::Config[:plugin_path] << "./lib"
server = Glint::Server.new(8500, { :timeout => 3 }) do |port|
  dir = Dir.tmpdir
  exec "consul", "agent", "-data-dir", dir, "-server", "-bootstrap"
end
server.start
$o = Ohai::System.new
$o.all_plugins
puts $o[:consul]

class TestOhaiPluginConsul < Test::Unit::TestCase
  def setup
    @consul = $o[:consul]
  end

  def test_base
    assert_not_nil @consul
  end

  def test_agent
    assert_equal({}, @consul[:agent][:checks])
    assert_equal 1, @consul[:agent][:members].size
  end

  def test_catalog
    assert_equal(["dc1"], @consul[:catalog][:datacenters])
    assert_equal(1, @consul[:catalog][:nodes].size)
    node_name = @consul[:catalog][:nodes][0]["Node"]
    assert_not_nil @consul[:catalog][:node][node_name]

    assert_equal({"consul" => nil}, @consul[:catalog][:services])
    assert_not_nil @consul[:catalog][:service]["consul"]
  end

  def test_status
    assert_not_nil @consul[:status][:leader]
    assert_not_nil @consul[:status][:peers]
  end

end
