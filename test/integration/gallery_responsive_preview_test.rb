require "test_helper"

class GalleryResponsivePreviewTest < ActionDispatch::IntegrationTest
  test "each example exposes an accessible same-origin responsive viewport" do
    get gallery_component_path("flex")

    assert_response :success
    assert_select "[data-gallery-example='flex-responsive-arrangement']" do
      assert_select "[role='tab']", text: "Preview"
      assert_select "[role='tab']", text: "Responsive"
      assert_select "[role='tab']", text: "Code"
      assert_select "[data-controller='gallery--preview'][data-gallery-preview-mode='full-width']" do
        assert_select "input[type='range'][min='320'][step='1'][aria-describedby]", count: 1
        assert_select "[role='separator'][tabindex='0'][aria-label][aria-orientation='vertical']", count: 1
        assert_select "select[data-gallery--preview-target='preset'] option[value]", count: 11
        assert_select "option[value='639']", text: "Below sm · 639 px"
        assert_select "option[value='640']", text: "sm · 640 px"
        assert_select "option[value='1535']", text: "Below 2xl · 1535 px"
        assert_select "option[value='1536']", text: "2xl · 1536 px"
        assert_select "button", text: "Reset"
        assert_select "button", text: "Full width"
        assert_select "iframe[title='One layout, three arrangements responsive preview']" \
          "[src='/gallery/previews/component/flex/flex-responsive-arrangement']",
          count: 1
      end
    end
  end

  test "preview endpoint renders only the selected executable example with full assets" do
    get gallery_preview_path(
      kind: :component,
      slug: "flex",
      example: "flex-responsive-arrangement"
    )

    assert_response :success
    assert_select "html[data-gallery='document'][data-gallery-preview-document='true']"
    assert_select "link[rel='stylesheet'][href*='nitro_kit']"
    assert_select "link[rel='stylesheet'][href*='gallery']"
    assert_select "script[type='importmap']"
    assert_select "#gallery-shell", count: 0
    assert_select "main[data-gallery='example'][data-gallery-responsive-preview='true']" \
      "[data-gallery-example='flex-responsive-arrangement']",
      count: 1
    assert_select "#gallery-flex-responsive[data-nk='flex'][data-dir='col md:row']", count: 1
    assert_select "[data-gallery-example='flex-every-breakpoint']", count: 0
  end

  test "flow preview keeps its state while unknown entries states and examples are not found" do
    get gallery_preview_path(
      kind: :composition,
      slug: "settings",
      example: "settings-appearance",
      state: "appearance"
    )

    assert_response :success
    assert_select "[data-gallery-example='settings-appearance'][data-gallery-responsive-preview='true']"
    assert_select "[data-gallery-composition-state='appearance']"

    get gallery_preview_path(kind: :component, slug: "missing", example: "anything")
    assert_response :not_found
    get gallery_preview_path(kind: :composition, slug: "settings", example: "settings-appearance", state: "missing")
    assert_response :not_found
    get gallery_preview_path(kind: :component, slug: "flex", example: "missing")
    assert_response :not_found
  end

  test "every catalog route declares unique resolvable example previews" do
    preview_paths = []

    Gallery::Catalog.entries.reject { |entry| entry.kind == :home }.each do |entry|
      states = entry.states.any? ? entry.states : [ nil ]

      states.each do |state|
        get Gallery::Catalog.path_for(entry, routes: Rails.application.routes.url_helpers, state:)
        assert_response :success

        examples = css_select("[data-gallery='example']")
        slugs = examples.map { |example| example["data-gallery-example"] }
        paths = examples.filter_map { |example| example.at_css("iframe[data-gallery='preview-iframe']")&.[]("src") }

        assert_equal slugs.uniq, slugs, "duplicate example slug on #{entry.slug} #{state}"
        assert_equal slugs.size, paths.size, "missing responsive preview on #{entry.slug} #{state}"
        preview_paths.concat(paths)
      end
    end

    preview_paths.uniq.each do |path|
      get path
      assert_response :success, "unresolved responsive preview #{path}"
    end
  end
end
