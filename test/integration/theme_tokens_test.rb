require "test_helper"

# The theming contract is the documented `--nk-*` custom properties: the set in
# `tokens.css`, the set in `docs/customization.md`, and the set the shipped
# bundle actually serves must be the same set, and component CSS must consume
# only tokens that exist. Scoped-override behavior is proven in
# `test/system/theme_tokens_test.rb`.
class ThemeTokensTest < ActionDispatch::IntegrationTest
  ROOT = NitroKit::Engine.root
  TOKENS_CSS = ROOT.join("src/stylesheets/nitro_kit/tokens.css").read.freeze
  CUSTOMIZATION_GUIDE = ROOT.join("docs/customization.md").read.freeze
  COMPONENT_SOURCES = ROOT.glob("src/stylesheets/nitro_kit/components/**/*.css").freeze

  DECLARED = TOKENS_CSS.scan(/^\s*(--nk-[a-z0-9-]+):/).flatten.uniq.sort.freeze
  DOCUMENTED = CUSTOMIZATION_GUIDE.scan(/^\| `(--nk-[a-z0-9-]+)`/).flatten.uniq.sort.freeze

  test "the documented token set is exactly the token set tokens.css declares" do
    assert_predicate DECLARED, :any?
    assert_equal DOCUMENTED, DECLARED
    assert_no_match(/^\| `--_nk-/, CUSTOMIZATION_GUIDE)
  end

  test "every documented token is served by the bundled stylesheet" do
    get ActionController::Base.helpers.asset_path("nitro_kit.css")

    assert_response :success
    assert_equal "text/css", response.media_type

    missing = DOCUMENTED.reject { |token| response.body.include?("#{token}:") }
    assert_empty missing, "documented tokens missing from the bundle: #{missing.join(", ")}"
  end

  test "component CSS consumes only declared public tokens or private mechanics" do
    consumed = COMPONENT_SOURCES.flat_map do |path|
      path.read.scan(/var\((--nk-[a-z0-9-]+)/).flatten
    end.uniq.sort

    assert_predicate consumed, :any?
    assert_empty consumed - DECLARED,
      "component CSS references undeclared public tokens: #{(consumed - DECLARED).join(", ")}"
  end

  test "public tokens are themeable because they are declared without escalation" do
    refute_includes TOKENS_CSS, "!important"
    assert_includes TOKENS_CSS, ":where(:root)"
    assert_includes TOKENS_CSS, ':where(:root, [data-theme="light"])'
  end

  test "the gallery loads Nitro Kit before its own styles so overrides win" do
    get gallery_root_path

    assert_response :success

    hrefs = css_select("link[rel='stylesheet']").map { |link| link["href"] }
    nitro = hrefs.index { |href| href.include?("nitro_kit") }
    gallery = hrefs.index { |href| href.include?("gallery") }

    assert nitro, "expected the Nitro Kit stylesheet"
    assert gallery, "expected the gallery stylesheet"
    assert_operator nitro, :<, gallery
    assert_empty hrefs.grep(/customize/)
  end
end
