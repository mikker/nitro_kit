require "test_helper"

class CssAssetTest < ActionDispatch::IntegrationTest
  test "serves Nitro Kit CSS through the Rails asset pipeline" do
    get asset_path("nitro_kit.css")

    assert_response :success
    assert_equal "text/css", response.media_type
    assert_includes response.body, "nitro-kit.tokens"
    assert_includes response.body, "--nk-color-canvas"
  end

  test "serves the optional Tailwind v4 adapter separately" do
    get asset_path("nitro_kit-tailwind-v4.css")

    assert_response :success
    assert_equal "text/css", response.media_type
    assert_includes response.body, "@layer properties, theme, base, nitro-kit, components, utilities"
  end

  private
    def asset_path(logical_path)
      ActionController::Base.helpers.asset_path(logical_path)
    end
end
