require "test_helper"

class GalleryTest < ActionDispatch::IntegrationTest
  test "gallery renders a Phlex document and home page" do
    get gallery_root_path

    assert_response :success
    assert_select "html[data-gallery='document']:not([data-theme])"
    assert_select "script[data-nk-appearance-default='system']"
    assert_select "body[data-gallery='body']"
    assert_select "#gallery-shell[data-gallery='shell'][data-nk='app-shell'][data-layout='sidebar']"
    assert_select "#gallery-shell > [data-slot='app-shell-sidebar'] " \
      "#gallery-navigation[data-nk='app-navigation'][data-turbo-permanent]" \
      "[data-controller='gallery--navigation']"
    assert_select "#gallery-navigation > [data-slot='app-navigation-header'] " \
      "#gallery-filter[data-nk='command-palette'][data-gallery='filter']" do
      assert_select "button[data-slot='command-palette-trigger'][command='show-modal'] " \
        "[data-slot='command-palette-trigger-label']", text: "Search gallery…"
      assert_select "input[type='search'][aria-label='Search gallery…'][placeholder='Search destinations…']"
      assert_select "[data-slot='command-palette-destination']",
        count: 3 + Gallery::Catalog.collections.sum { _1.entries.size }
    end
    assert_select "[data-gallery='main'] div[data-gallery='page'][data-gallery-page='home']"
    assert_select "h1", text: "Nitro Kit"
    assert_select "[data-gallery='introduction'] section", count: 3
    assert_select "[data-gallery='introduction'] h2", text: "What this is"
    assert_select "[data-gallery='introduction'] h2", text: "Who each surface serves"
    assert_select "[data-gallery='introduction'] h2", text: "The idea"
  end

  test "gallery renders every catalog category through AppNavigation sections" do
    get gallery_root_path

    assert_response :success
    navigation = css_select("#gallery-navigation").sole
    sections = navigation.css("[data-slot='app-navigation-section']")
    labels = sections.map { |section| section.at_css("[data-slot='app-navigation-section-label']").text }

    assert_equal Gallery::Catalog.collections.flat_map { |collection|
      collection.categories.map { |category| "#{collection.title} · #{category.title}" }
    }, labels
    Gallery::Catalog.collections.each do |collection|
      collection_sections = sections.select do |section|
        section.at_css("[data-slot='app-navigation-section-label']").text.start_with?("#{collection.title} · ")
      end
      assert_equal collection.entries.map(&:title),
        collection_sections.flat_map { |section|
          section.css("[data-slot='app-navigation-item-label']").map(&:text)
        }
    end
    assert_select "[data-gallery='navigation'] a", text: "Blocks", count: 0
    assert_select "[data-gallery='navigation'] a", text: "Flows", count: 0
  end

  test "command palette page previews its dialog and serves Turbo Frame results" do
    get gallery_component_path("command-palette")

    assert_response :success
    assert_select "[data-gallery='command-palette-dialog-preview']"
    assert_select "#reference-contract [data-gallery='contract-options'] li", count: 4
    assert_select "#reference-contract [data-gallery='contract-options'] li", text: /required id:/i
    assert_select "#reference-contract [data-gallery='contract-options'] li", text: /search_url: nil/
    assert_select "#gallery-command-palette-async form[action='#{gallery_command_palette_results_path}']" \
      "[data-turbo-frame='gallery-command-palette-async-results-frame']"

    get gallery_command_palette_results_path(query: "billing")

    assert_response :success
    assert_select "turbo-frame#gallery-command-palette-async-results-frame[target='_top']" do
      assert_select "[data-slot='command-palette-destination']", count: 1
      assert_select "[data-slot='command-palette-destination-label']", text: "Billing"
    end

    get gallery_command_palette_results_path(query: "missing")

    assert_response :success
    assert_select "turbo-frame#gallery-command-palette-async-results-frame"
    assert_select "[data-slot='command-palette-destination']", count: 0
  end

  test "current composition entry remains current on every state" do
    get gallery_composition_path(slug: "settings", state: "appearance")

    assert_response :success
    assert_select "#gallery-navigation a[href='/gallery/compositions/settings/profile'][aria-current='page']",
      text: "Workspace settings"
    assert_select "[data-gallery='navigation'] a[aria-current='page']", count: 1
  end

  test "gallery is the canonical dummy application root" do
    get root_path

    assert_response :success
    assert_select "html[data-gallery='document']"
    assert_select "[data-gallery-page='home'] h1", text: "Nitro Kit"
  end

  test "gallery loads Nitro and gallery styles with the import map" do
    get gallery_root_path

    assert_response :success
    assert_select "link[rel='stylesheet'][href*='nitro_kit']"
    assert_select "link[rel='stylesheet'][href*='gallery']"
    assert_select "script[type='importmap']"
  end

  test "appearance bootstrap precedes every stylesheet" do
    get gallery_root_path

    head = Nokogiri::HTML(response.body).at_css("head")
    bootstrap = head.at_css("script[data-nk-appearance-default]")
    positions = head.element_children.each_with_index.to_h

    assert bootstrap
    head.css("link[rel='stylesheet']").each do |stylesheet|
      assert_operator positions.fetch(bootstrap), :<, positions.fetch(stylesheet)
    end
  end

  test "gallery accepts explicit appearance defaults while unknown values return to system" do
    get gallery_root_path(theme: "dark")

    assert_response :success
    assert_select "html[data-theme='dark'][data-theme-preference='dark']"
    assert_select "script[data-nk-appearance-default='dark']"
    assert_select "[data-gallery='theme-switcher'] [data-nk='appearance-picker']"

    get gallery_root_path(theme: "unknown")

    assert_response :success
    assert_select "html:not([data-theme]):not([data-theme-preference])"
    assert_select "script[data-nk-appearance-default='system']"
  end

  test "catalog routes are stable and unknown entries return not found" do
    assert_routing(
      "/gallery/components/button",
      controller: "gallery/components",
      action: "show",
      slug: "button"
    )
    assert_routing(
      "/gallery/components/page-header",
      controller: "gallery/components",
      action: "show",
      slug: "page-header"
    )
    assert_routing(
      "/gallery/compositions/dashboard/active",
      controller: "gallery/compositions",
      action: "show",
      slug: "dashboard",
      state: "active"
    )

    get gallery_component_path("button")
    assert_response :success

    get gallery_component_path("page-header")
    assert_response :success
    assert_select "div[data-gallery-page='page-header']"

    get gallery_composition_path(slug: "dashboard", state: "active")
    assert_response :success
    assert_select "div[data-gallery-page='dashboard'][data-gallery-state='active']"

    get gallery_component_path("missing")
    assert_response :not_found

    get gallery_component_path("missing")
    assert_response :not_found
  end

  test "gallery markup does not rely on classes or inline styles" do
    get gallery_root_path

    assert_response :success
    assert_select "[class]", count: 0
    assert_select "[style]", count: 0
  end
end
