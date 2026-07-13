require "test_helper"

class GalleryLayoutsTest < ActionDispatch::IntegrationTest
  LAYOUTS = %w[v-stack h-stack grid container].freeze

  test "catalog exposes only the four evidence-backed layout routes" do
    layout_entries = Gallery::Catalog.entries(kind: :component).select { |entry| entry.group == "Layout" }

    assert_equal LAYOUTS, layout_entries.map(&:slug)
    assert_equal(
      LAYOUTS.map { |slug| "/gallery/components/#{slug}" },
      layout_entries.map { |entry| Gallery::Catalog.path_for(entry, routes: Rails.application.routes.url_helpers) }
    )
    assert_empty Gallery::Catalog.entries(kind: :component).map(&:slug) & %w[spacer split frame]
  end

  test "every layout page is direct class-free Phlex in light and dark themes" do
    LAYOUTS.each do |slug|
      %w[light dark].each do |theme|
        get gallery_component_path(slug, theme:)

        assert_response :success
        assert_select "html[data-theme='#{theme}']"
        assert_select "div[data-gallery='page'][data-gallery-page='#{slug}']"
        assert_select "[data-gallery='example-canvas'] [data-nk='#{slug}'][id]", minimum: 1
        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
      end
    end
  end

  test "vertical stack page covers all spacing alignment cardinality pressure and nesting" do
    get_layout("v-stack")

    NitroKit::VStack::GAPS.each do |gap|
      assert_select "#gallery-v-stack-gap-#{gap}[data-nk='v-stack'][data-gap='#{gap}'][data-align='start']"
    end
    NitroKit::VStack::ALIGNMENTS.each do |align|
      assert_select "#gallery-v-stack-align-#{align}[data-align='#{align}']"
    end

    assert_select "#gallery-v-stack-empty:empty"
    assert_select "#gallery-v-stack-one > [data-nk='card']", count: 1
    assert_select "#gallery-v-stack-many > [data-nk='badge']", count: 12
    assert_select "#gallery-v-stack-long[data-align='stretch']" do
      assert_select "> [data-nk='alert']", count: 1
      assert_select "> [data-nk='card']", count: 1
    end
    assert_select "#gallery-v-stack-composition > [data-nk='h-stack']", count: 1
    assert_select "#gallery-v-stack-composition > [data-nk='grid'][data-cols='3']", count: 1
    assert_select "#gallery-v-stack-metrics > [data-nk='card']", count: 3
  end

  test "horizontal stack page covers every row option and preserves explicit wrapping" do
    get_layout("h-stack")

    NitroKit::HStack::GAPS.each do |gap|
      assert_select "#gallery-h-stack-gap-#{gap}[data-gap='#{gap}']"
    end
    NitroKit::HStack::ALIGNMENTS.each do |align|
      assert_select "#gallery-h-stack-align-#{align}[data-align='#{align}']"
    end
    NitroKit::HStack::JUSTIFICATIONS.each do |justify|
      assert_select "#gallery-h-stack-justify-#{justify}[data-justify='#{justify}']"
    end

    assert_select "#gallery-h-stack-wrap-false[data-wrap='false'] > [data-nk='button']", count: 8
    assert_select "#gallery-h-stack-wrap-true[data-wrap='true'] > [data-nk='button']", count: 8
    assert_select "#gallery-h-stack-empty:empty"
    assert_select "#gallery-h-stack-one > [data-nk='badge']", count: 1
    assert_select "#gallery-h-stack-many-long[data-wrap='true'] > [data-nk='badge']", count: 3
    assert_select "#gallery-h-stack-record-row[data-justify='between'][data-wrap='true']"
    assert_select "#gallery-h-stack-record-actions > [data-nk='button']", count: 2
  end

  test "grid page uses only three columns across empty partial dense long and nested compositions" do
    get_layout("grid")

    assert_select "[data-gallery='example-canvas'] [data-nk='grid']", minimum: 1 do |grids|
      assert grids.all? { |grid| grid["data-cols"] == "3" }
    end
    assert_select "#gallery-grid-metrics > [data-nk='card']", count: 3
    assert_select "#gallery-grid-responsive > [data-nk='card']", count: 3
    assert_select "#gallery-grid-empty:empty"
    assert_select "#gallery-grid-one > [data-nk='card']", count: 1
    assert_select "#gallery-grid-many > [data-nk='card']", count: 9
    assert_select "#gallery-grid-uneven > [data-nk='card']", count: 3
    assert_select "#gallery-grid-uneven", text: /International Research, Production, and Reliability Engineering/
    assert_select "#gallery-grid-team > [data-nk='card']", count: 3
    assert_select "#gallery-grid-team [data-nk='v-stack']", count: 3
    assert_select "#gallery-grid-team [data-nk='h-stack']", count: 3
  end

  test "container page covers every token width and documents omission for full width" do
    get_layout("container")

    NitroKit::Container::SIZES.each do |size|
      assert_select "#gallery-container-size-#{size}[data-nk='container'][data-size='#{size}']"
    end
    assert_select "[data-nk='container'][data-size='full']", count: 0
    assert_select "#gallery-container-empty:empty"
    assert_select "#gallery-container-one > [data-nk='button']", count: 1
    assert_select "#gallery-container-many [data-nk='alert']", count: 6
    assert_select "#gallery-container-composition-grid > [data-nk='card']", count: 3
    assert_select "#gallery-container-deferred-alert", text: /Spacer has no elastic-gap evidence/
    assert_select "[data-gallery='notes'] code", text: /No Spacer, Split, Frame/

    document = Nokogiri::HTML(response.body)
    full_width_card = document.at_css("#gallery-container-full-width-card")
    assert full_width_card
    assert_nil full_width_card.ancestors.find { |ancestor| ancestor["data-nk"] == "container" }
  end

  private

  def get_layout(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
