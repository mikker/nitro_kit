require "test_helper"

class GalleryTest < ActionDispatch::IntegrationTest
  test "gallery renders a Phlex document and home page" do
    get gallery_root_path

    assert_response :success
    assert_select "html[data-gallery='document'][data-theme='light']"
    assert_select "body[data-gallery='body']"
    assert_select "[data-gallery='sidebar']"
    assert_select "[data-gallery='main'] div[data-gallery='page'][data-gallery-page='home']"
    assert_select "h1", text: "Component gallery"
    assert_select "[data-gallery='index-group']", count: 3
    assert_select "[data-gallery='index-group'][data-gallery-kind='component'] h2", text: "Components"
    assert_select "[data-gallery='index-group'][data-gallery-kind='block'] h2", text: "Blocks"
    assert_select "[data-gallery='index-group'][data-gallery-kind='flow'] h2", text: "Flows"
  end

  test "gallery is the canonical dummy application root" do
    get root_path

    assert_response :success
    assert_select "html[data-gallery='document']"
    assert_select "[data-gallery-page='home'] h1", text: "Component gallery"
  end

  test "gallery loads Nitro and gallery styles with the import map" do
    get gallery_root_path

    assert_response :success
    assert_select "link[rel='stylesheet'][href*='nitro_kit']"
    assert_select "link[rel='stylesheet'][href*='gallery']"
    assert_select "script[type='importmap']"
  end

  test "gallery uses deterministic theme URLs" do
    get gallery_root_path(theme: "dark")

    assert_response :success
    assert_select "html[data-theme='dark']"
    assert_select "[data-gallery='theme-switcher'] a[aria-current='page']", text: "Dark"

    get gallery_root_path(theme: "unknown")

    assert_response :success
    assert_select "html[data-theme='light']"
  end

  test "catalog routes are stable and unknown entries return not found" do
    assert_routing(
      "/gallery/components/button",
      controller: "gallery/components",
      action: "show",
      slug: "button"
    )
    assert_routing(
      "/gallery/blocks/page-header",
      controller: "gallery/blocks",
      action: "show",
      slug: "page-header"
    )
    assert_routing(
      "/gallery/flows/dashboard/active",
      controller: "gallery/flows",
      action: "show",
      slug: "dashboard",
      state: "active"
    )

    get gallery_component_path("button")
    assert_response :success

    get gallery_block_path("page-header")
    assert_response :success
    assert_select "div[data-gallery-page='page-header']"

    get gallery_flow_path(slug: "dashboard", state: "active")
    assert_response :success
    assert_select "div[data-gallery-page='dashboard'][data-gallery-state='active']"

    get gallery_component_path("missing")
    assert_response :not_found

    get gallery_block_path("missing")
    assert_response :not_found
  end

  test "gallery markup does not rely on classes or inline styles" do
    get gallery_root_path

    assert_response :success
    assert_select "[class]", count: 0
    assert_select "[style]", count: 0
  end
end
