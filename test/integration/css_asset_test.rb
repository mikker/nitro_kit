require "test_helper"

class CssAssetTest < ActionDispatch::IntegrationTest
  test "serves Nitro Kit CSS through the Rails asset pipeline" do
    get asset_path("nitro_kit.css")

    assert_response :success
    assert_equal "text/css", response.media_type
    assert_includes response.body, "nitro-kit.tokens"
    assert_includes response.body, "--nk-color-canvas"
  end

  test "ships the Tailwind v4 layer order and theme aliases inside nitro_kit.css" do
    get asset_path("nitro_kit.css")

    assert_includes response.body, "@layer properties, theme, base, nitro-kit, components, utilities"
    assert_includes response.body, "--color-background: var(--nk-color-canvas)"
  end

  test "no longer serves the retired Tailwind v4 adapter" do
    assert_raises(Propshaft::MissingAssetError) { asset_path("nitro_kit-tailwind-v4.css") }
  end

  test "keeps the Tailwind engine entry out of the asset pipeline" do
    assert_raises(Propshaft::MissingAssetError) { asset_path("nitro_kit/engine.css") }
  end

  private
    def asset_path(logical_path)
      ActionController::Base.helpers.asset_path(logical_path)
    end
end
