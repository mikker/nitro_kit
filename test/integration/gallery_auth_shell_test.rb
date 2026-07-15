require "test_helper"

class GalleryAuthShellTest < ActionDispatch::IntegrationTest
  AUTH_FLOW_STATES = {
    "sign-in" => %w[default invalid loading success mobile],
    "password-reset" => %w[request validation sent update expired loading]
  }.freeze

  test "catalog exposes the evidence-backed auth shell without speculative shells" do
    entry = Gallery::Catalog.fetch!(kind: :block, slug: "auth-shell")

    assert_equal "Shells", Gallery::Catalog.category_for(entry).title
    assert_equal "/gallery/blocks/auth-shell", Gallery::Catalog.path_for(entry, routes: Rails.application.routes.url_helpers)
    block_slugs = Gallery::Catalog.entries(kind: :block).map(&:slug)
    assert_includes block_slugs, "app-shell"
    assert_empty block_slugs & %w[marketing-shell authentication-panel]
  end

  test "renders every auth shell composition in light and dark themes" do
    %w[light dark].each do |theme|
      get gallery_block_path("auth-shell", theme:)

      assert_response :success
      assert_select "html[data-theme='#{theme}']"
      assert_select "div[data-gallery='page'][data-gallery-page='auth-shell']"
      assert_select "[data-gallery='example-canvas'] main[data-nk='auth-shell'][id]", count: 7
      assert_select "[data-gallery='example-canvas'] [class]", count: 0
      assert_select "[data-gallery='example-canvas'] [style]", count: 0
      assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
    end
  end

  test "every example preserves the fixed container and stack composition" do
    get gallery_block_path("auth-shell")

    assert_response :success
    assert_select "main[data-nk='auth-shell']", count: 7 do |shells|
      shells.each do |shell|
        assert_equal 1, shell.element_children.count
        container = shell.element_children.first
        assert_equal 1, container.element_children.count
        stack = container.element_children.first

        assert_equal "container", container["data-nk"]
        assert_equal "md", container["data-size"]
        assert_equal "flex", stack["data-nk"]
        assert_equal "col", stack["data-dir"]
        assert_equal "6", stack["data-gap"]
        assert_equal "stretch", stack["data-align"]
      end
    end
  end

  test "examples prove caller ownership across forms branding Turbo state and pressure" do
    get gallery_block_path("auth-shell")

    assert_response :success
    assert_select "#gallery-auth-shell-credentials-card[data-nk='card']"
    assert_select "#gallery-auth-shell-credentials-form input[type='email'][required]"
    assert_select "#gallery-auth-shell-credentials-form input[type='password'][value]", count: 0

    assert_select "#gallery-auth-shell-branding > [data-nk='container'] > [data-nk='flex'][data-dir='col']" do
      assert_select "> header[data-gallery='auth-branding']"
      assert_select "> #gallery-auth-shell-branding-card[data-nk='card']"
    end

    assert_select "turbo-frame#gallery-auth-shell-frame > #gallery-auth-shell-turbo[data-nk='auth-shell']"
    assert_select "#gallery-auth-shell-validation-alert[data-variant='error']"
    assert_select "#gallery-auth-shell-validation-form [data-nk='field'][data-state='invalid']", minimum: 2
    assert_select "#gallery-auth-shell-success-alert[data-variant='success']"
    assert_select "#gallery-auth-shell-long-copy-card", text: /katherine\.johnson\+analytical-engines/
    assert_select "#gallery-auth-shell-mobile[data-gallery='flow-surface'][data-gallery-mobile='true']"
  end

  test "sign in and password recovery use the shell without surrendering Turbo lifecycle" do
    AUTH_FLOW_STATES.each do |slug, states|
      states.each do |state|
        get gallery_flow_path(slug:, state:)

        assert_response :success
        assert_select "main[data-nk='auth-shell'][data-gallery='flow-surface']", count: 1 do
          assert_select "> [data-nk='container'][data-size='md'] > [data-nk='flex'][data-dir='col'][data-gap='6'][data-align='stretch'] > turbo-frame", count: 1
          assert_select "turbo-frame > [data-nk='card'][id]", count: 1
        end
      end
    end
  end
end
