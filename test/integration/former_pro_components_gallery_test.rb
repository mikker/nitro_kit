require "test_helper"

class FormerProComponentsGalleryTest < ActionDispatch::IntegrationTest
  test "details table gallery executes every example and exposes its Ruby source" do
    get gallery_component_path("details-table")

    assert_response :success
    assert_select "[data-gallery-page='details-table']"
    assert_select "[data-gallery='example']", count: 4
    assert_select "[data-gallery='code-source']", count: 4
    assert_select "[data-gallery='code-source']", text: /NitroKit::DetailsTable\.new/
    assert_select "#gallery-details-table-profile[data-nk='details-table']"
    assert_select "#gallery-details-table-profile [data-nk='table'][data-slot='details-table-table']"
    assert_select "#gallery-details-table-values [data-slot='details-table-empty']", text: "Not provided"
    assert_select "#gallery-details-table-profile [data-slot='details-table-boolean']", text: "Yes"
    assert_select "#gallery-details-table-status-badge[data-nk='badge']", text: "Active"
    assert_select "#gallery-details-table-card [data-nk='progressive-image']"
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
  end

  test "progressive image gallery renders server states and one accessible image" do
    get gallery_component_path("progressive-image")

    assert_response :success
    assert_select "[data-gallery-page='progressive-image']"
    assert_select "[data-gallery='example']", count: 5
    assert_select "[data-gallery='code-source']", count: 5
    assert_select "[data-gallery='code-source']", text: /NitroKit::ProgressiveImage\.new/

    assert_select "#gallery-progressive-image-loaded[data-state='loading'][aria-busy='true']"
    assert_select "#gallery-progressive-image-loaded [data-slot='progressive-image-placeholder'][alt=''][aria-hidden='true']"
    assert_select "#gallery-progressive-image-loaded [data-slot='progressive-image-image'][alt='Abstract indigo workspace illustration']"
    assert_select "#gallery-progressive-image-loaded img:not([alt=''])", count: 1

    assert_select "#gallery-progressive-image-empty[data-state='empty']:not([data-controller])"
    assert_select "#gallery-progressive-image-empty img", count: 0
    assert_select "#gallery-progressive-image-empty [data-slot='progressive-image-fallback']:not([role])", text: "Workspace cover"
    assert_select "#gallery-progressive-image-error [data-slot='progressive-image-fallback'][role='status']", text: "Unavailable workspace cover"

    assert_select "#gallery-progressive-image-decorative [data-slot='progressive-image-placeholder'][alt=''][aria-hidden='true']"
    assert_select "#gallery-progressive-image-decorative [data-slot='progressive-image-image'][alt='']"
    assert_select "#gallery-progressive-image-decorative [data-slot='progressive-image-fallback'][aria-hidden='true']:not([role])"
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
  end
end
