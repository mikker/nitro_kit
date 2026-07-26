require "test_helper"

class GalleryTest < ActionDispatch::IntegrationTest
  test "gallery renders a Phlex document and home page" do
    get gallery_root_path

    assert_response :success
    assert_select "html[data-gallery='document']:not([data-theme])"
    assert_select "script[data-nk-appearance-default='system']"
    assert_select "body[data-gallery='body']"
    assert_select "[data-gallery='sidebar']"
    assert_select "[data-gallery='main'] div[data-gallery='page'][data-gallery-page='home']"
    assert_select "h1", text: "Nitro Kit"
    assert_select "[data-gallery='introduction'] section", count: 2
    assert_select "[data-gallery='introduction'] h2", text: "The idea"
    assert_select "[data-gallery='introduction'] h2", text: "The rules"
    assert_select "[data-gallery='introduction'] li", count: 4
  end

  test "gallery renders components grouped by subcategory and nested composition categories" do
    get gallery_root_path

    assert_response :success
    assert_select "[data-gallery='navigation-collection'][data-gallery-kind='component']" do |collections|
      assert_select "details[data-gallery='navigation-category']", count: 6
      assert_select "details[data-gallery-category='layout'] > summary", text: "Layout"
      assert_select "details[data-gallery-category='navigation'] > summary", text: "Navigation"
      assert_select "details[data-gallery-category='forms'] > summary", text: "Forms"
      assert_select "details[data-gallery-category='data'] > summary", text: "Data display"
      assert_select "details[data-gallery-category='feedback'] > summary", text: "Feedback"
      assert_select "details[data-gallery-category='actions'] > summary", text: "Actions"
      assert_equal(
        Gallery::Catalog.entries(kind: :component).map(&:title),
        collections.first.css("ul a").map(&:text)
      )
    end
    assert_select "[data-gallery='navigation-collection'][data-gallery-kind='composition']" do
      assert_select "[data-gallery='navigation-description']",
        text: "Executable composition tests: the system exercised whole."
      assert_select "details[data-gallery='navigation-category']", count: 7
      assert_select "details[data-gallery-category='access-and-onboarding'] > summary", text: "Access & onboarding"
      assert_select "details[data-gallery-category='complete-applications'] > summary", text: "Complete applications"
    end
    assert_select "[data-gallery='navigation'] a", text: "Blocks", count: 0
    assert_select "[data-gallery='navigation'] a", text: "Flows", count: 0
  end

  test "current composition category stays open and its entry remains current on every state" do
    get gallery_composition_path(slug: "settings", state: "appearance")

    assert_response :success
    assert_select "details[data-gallery-category='workspace-and-organization'][open]" do
      assert_select "a[href='/gallery/compositions/settings/profile'][aria-current='page']", text: "Workspace settings"
    end
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
