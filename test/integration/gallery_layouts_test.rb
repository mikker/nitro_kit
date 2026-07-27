require "test_helper"

class GalleryLayoutsTest < ActionDispatch::IntegrationTest
  LAYOUTS = %w[flex grid container].freeze

  test "catalog exposes the responsive layout routes" do
    layout_entries = LAYOUTS.map { |slug| Gallery::Catalog.fetch!(kind: :component, slug:) }

    assert_equal LAYOUTS, layout_entries.map(&:slug)
    assert_equal(
      LAYOUTS.map { |slug| "/gallery/components/#{slug}" },
      layout_entries.map { |entry| Gallery::Catalog.path_for(entry, routes: Rails.application.routes.url_helpers) }
    )
    assert_empty Gallery::Catalog.entries(kind: :component).map(&:slug) & %w[v-stack h-stack spacer split frame]
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

  test "flex page covers responsive shorthand and every closed layout value" do
    get_layout("flex")

    assert_select(
      "#gallery-flex-responsive[data-nk='flex']" \
        "[data-dir='col md:row']" \
        "[data-gap='2 md:4 lg:6']" \
        "[data-align='stretch md:center']" \
        "[data-justify='start lg:between']" \
        "[data-wrap='nowrap md:wrap']"
    )

    %w[row col row-reverse col-reverse].each do |direction|
      assert_select "#gallery-flex-dir-#{direction}[data-dir='#{direction}'] > [data-nk='badge']", count: 3
    end
    %w[start center end stretch baseline].each do |alignment|
      assert_select "#gallery-flex-align-#{alignment}[data-align='#{alignment}']"
    end
    %w[start center end between around evenly].each do |justification|
      assert_select "#gallery-flex-justify-#{justification}[data-justify='#{justification}']"
    end
    %w[nowrap wrap wrap-reverse].each do |wrap|
      assert_select "#gallery-flex-wrap-#{wrap}[data-wrap='#{wrap}'] > [data-nk='button']", count: 8
    end

    assert_select "#gallery-flex-gap-responsive[data-gap='1 sm:2 md:4 lg:8 xl:12 2xl:16']"
    assert_select(
      "#gallery-flex-breakpoints" \
        "[data-dir='col sm:row md:row-reverse lg:col-reverse xl:row 2xl:col']" \
        "[data-gap='1 sm:2 md:4 lg:8 xl:12 2xl:16']" \
        "[data-align='start sm:center md:end lg:stretch xl:baseline 2xl:center']" \
        "[data-justify='start sm:center md:end lg:between xl:around 2xl:evenly']" \
        "[data-wrap='nowrap sm:wrap md:wrap-reverse lg:nowrap xl:wrap 2xl:wrap-reverse']" \
        " > [data-nk='badge']",
      count: 6
    )
    assert_select "#gallery-flex-composition[data-dir='col lg:row'][data-justify='start lg:between']"
    assert_select "#gallery-flex-composition-actions[data-wrap='wrap'] > [data-nk='button']", count: 2
  end

  test "grid page covers scalar and responsive columns gaps cardinality and nested Flex" do
    get_layout("grid")

    assert_select "#gallery-grid-cards[data-cols='1 sm:2 lg:3'][data-gap='3 md:4 lg:6'] > [data-nk='card']", count: 3
    assert_select(
      "#gallery-grid-breakpoints" \
        "[data-cols='1 sm:2 md:3 lg:4 xl:6 2xl:12']" \
        "[data-gap='1 sm:2 md:3 lg:4 xl:6 2xl:8'] > [data-nk='badge']",
      count: 12
    )

    [ 1, 2, 3, 4, 6, 12 ].each do |cols|
      assert_select "#gallery-grid-cols-#{cols}[data-cols='#{cols}'] > [data-nk='badge']", count: cols
    end

    assert_select "#gallery-grid-catalog[data-cols='1 md:2 xl:4'][data-gap='2 lg:6'] > [data-nk='card']", count: 8
    assert_select "#gallery-grid-metrics[data-cols='2 lg:4 2xl:6'][data-gap='2 md:3'] > [data-nk='card']", count: 12
    assert_select "#gallery-grid-empty:empty"
    assert_select "#gallery-grid-one > [data-nk='card']", count: 1
    assert_select "#gallery-grid-many > [data-nk='card']", count: 9
    assert_select "#gallery-grid-team[data-cols='1 sm:2 lg:3'] > [data-nk='card']", count: 3
    assert_select "#gallery-grid-team [data-nk='flex'][data-dir='col']", count: 3
    assert_select "#gallery-grid-team [data-nk='flex'][data-dir='row']", count: 3
    assert_select "#gallery-grid-team", text: /International Research, Production, and Reliability Engineering/
  end

  test "badge-only grid examples align badges without changing Grid defaults" do
    gallery_css = Rails.root.join("app/assets/stylesheets/gallery.css").read

    assert_match(
      /:where\(\s*#gallery-grid-breakpoints,\s*\[id\^="gallery-grid-cols-"\]\s*\)\s*\{\s*justify-items: start;/,
      gallery_css
    )
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
    assert_select "#gallery-container-composition-grid[data-cols='1 sm:2 lg:3'] > [data-nk='card']", count: 3
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
