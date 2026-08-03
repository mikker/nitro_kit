require "test_helper"
require "nitro_kit/upgrade_smoke_test"

class UpgradeSmokeRouteLifecycleTest < ActiveSupport::TestCase
  test "requiring the helper does not install routes and lifecycle is idempotent and restoring" do
    owner = Object.new
    original_route_count = Rails.application.routes.routes.size

    assert_empty matching_routes("GET")
    assert_empty matching_routes("PATCH")
    assert host_root_route?

    NitroKit::UpgradeSmoke::RouteLifecycle.install!(owner)
    NitroKit::UpgradeSmoke::RouteLifecycle.install!(owner)

    assert_equal 1, matching_routes("GET").size
    assert_equal 1, matching_routes("PATCH").size

    NitroKit::UpgradeSmoke::RouteLifecycle.uninstall!(owner)

    assert_empty matching_routes("GET")
    assert_empty matching_routes("PATCH")
    assert_equal original_route_count, Rails.application.routes.routes.size
    assert host_root_route?
  ensure
    NitroKit::UpgradeSmoke::RouteLifecycle.uninstall!(owner)
  end

  test "installs ahead of a host catch-all route" do
    owner = Object.new
    catch_all = proc { get "*path", to: ->(_environment) { [ 204, {}, [] ] } }
    Rails.application.routes.append(&catch_all)
    Rails.application.reload_routes!

    NitroKit::UpgradeSmoke::RouteLifecycle.install!(owner)

    assert_equal NitroKit::UpgradeSmoke::PATH,
      matching_routes("GET").first.path.spec.to_s.split("(", 2).first
  ensure
    NitroKit::UpgradeSmoke::RouteLifecycle.uninstall!(owner)
    Rails.application.routes.instance_variable_get(:@append).delete(catch_all)
    Rails.application.reload_routes!
  end

  test "refuses to mask a host route" do
    owner = Object.new
    collision = proc { get NitroKit::UpgradeSmoke::PATH, to: ->(_environment) { [ 204, {}, [] ] } }
    Rails.application.routes.append(&collision)
    Rails.application.reload_routes!

    error = assert_raises(RuntimeError) do
      NitroKit::UpgradeSmoke::RouteLifecycle.install!(owner)
    end

    assert_includes error.message, "collides with host GET routing"
  ensure
    NitroKit::UpgradeSmoke::RouteLifecycle.uninstall!(owner)
    Rails.application.routes.instance_variable_get(:@append).delete(collision)
    Rails.application.reload_routes!
  end

  private
    def matching_routes(method)
      request = ActionDispatch::Request.new(
        Rack::MockRequest.env_for(NitroKit::UpgradeSmoke::PATH, method:)
      )
      matches = []
      Rails.application.routes.router.recognize(request) { |route| matches << route }
      matches
    end

    def host_root_route?
      request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/", method: "GET"))
      Rails.application.routes.router.recognize(request) { return true }
      false
    end
end
