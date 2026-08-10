require "test_helper"

class ProductResourceFlowTest < ActionDispatch::IntegrationTest
  STATES = %w[
    index filtered empty paginated new new-validation edit edit-validation active archived history narrow
  ].freeze

  test "catalog exposes one coherent product resource composition" do
    entry = Gallery::Catalog.fetch!(kind: :composition, slug: "product-resource")

    assert_equal STATES, entry.states
    assert_equal %w[app-shell app-navigation toolbar flex button], entry.expected_roots
    assert_match(/queryable indexes/, entry.description)

    STATES.each do |state|
      assert_equal(
        "/gallery/compositions/product-resource/#{state}",
        Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      )
    end

    get gallery_composition_path(slug: "product-resource", state: "invented")
    assert_response :not_found
  end

  test "the executable example body also renders through the preview route" do
    get gallery_preview_path(
      kind: "composition",
      slug: "product-resource",
      example: "product-resource-index",
      state: "index"
    )

    assert_response :success
    assert_select "#gallery-product-resource-shell[data-nk='app-shell']"
    assert_select "turbo-frame#gallery-product-resource-query[data-turbo-action='advance']"
  end

  test "every product state renders in one hybrid application shell from executable source" do
    STATES.each do |state|
      get_flow(state)

      assert_select "#gallery-product-resource-shell[data-nk='app-shell'][data-layout='hybrid']" \
        "[data-gallery='composition-surface'][data-gallery-composition='product-resource']" \
        "[data-gallery-composition-state='#{state}']" do
        assert_select "[data-slot='app-shell-topbar'] #gallery-product-resource-toolbar[data-nk='toolbar'] h1",
          count: 1
        assert_select "#gallery-product-resource-navigation[data-nk='app-navigation']" \
          " [data-slot='app-navigation-item-link'][aria-current='page']",
          text: "Products",
          count: 1
        assert_select "[data-gallery='product-resource-main']" do
          assert_select "> #gallery-product-resource-stack[data-nk='flex'][data-dir='col'][data-gap='6']",
            count: 1
          assert_select "> [data-nk='container']", count: 0
        end
      end
      assert_select "[data-gallery='composition-states'] a[aria-current='page']",
        text: state.tr("-", " ").humanize,
        count: 1
      assert_select "[data-gallery='example-canvas'] [class]", count: 0
      assert_select "[data-gallery='example-canvas'] [style]", count: 0

      assert_select "[data-gallery='code-path']", text: /product_resource_page\.rb/
      assert_select "[data-gallery='code-source']", text: /NitroKit::AppShell/
    end
  end

  test "query region keeps filters sorts results and pagination in one URL-driven frame" do
    get_flow("index")

    assert_select "turbo-frame#gallery-product-resource-query[data-turbo-action='advance']" do
      assert_select "#gallery-product-resource-filters[method='get']" \
        "[action='/gallery/compositions/product-resource/filtered']" \
        "[data-turbo-frame='gallery-product-resource-query'][data-turbo-action='replace']"
      assert_select "#gallery-product-resource-filter-query[name='q[query]'][type='search']"
      assert_select "#gallery-product-resource-filter-status[name='q[status]']"
      assert_select "a[href='/gallery/compositions/product-resource/index']" \
        "[data-turbo-frame='gallery-product-resource-query'][data-turbo-action='replace']",
        text: "Reset"
      assert_select "#gallery-product-resource-table[data-sort='name'][data-direction='asc']" do
        assert_select "thead a[data-slot='table-sort'][data-turbo-action='replace']", count: 3
        assert_select "tbody tr", count: 4
        assert_select "tbody [data-nk='button'][data-turbo-frame='_top']", count: 8
        assert_select "tbody a[href*='product_id=product_release_console']", count: 2
      end
      assert_select "#gallery-product-resource-pagination-bar[data-nk='pagination-bar']"
      assert_select "#gallery-product-resource-pagination a[href*='/product-resource/paginated']" \
        "[href*='page=2']",
        minimum: 1
    end

    get_flow("filtered")
    assert_select "turbo-frame#gallery-product-resource-query[data-turbo-action='advance']"
    assert_select "#gallery-product-resource-filter-query[value='Sensor']"
    assert_select "#gallery-product-resource-filter-status option[value='active'][selected]"
    assert_select "#gallery-product-resource-table tbody tr", count: 1, text: /Sensor Gateway/
    assert_select "#gallery-product-resource-table thead a[href*='q%5Bquery%5D=Sensor']", minimum: 1
    assert_select "#gallery-product-resource-table thead a[href*='q%5Bstatus%5D=active']", minimum: 1

    get_flow("empty")
    assert_select "turbo-frame#gallery-product-resource-query[data-turbo-action='advance']" do
      assert_select "#gallery-product-resource-empty[data-nk='empty-state']"
      assert_select "#gallery-product-resource-table", count: 0
      assert_select "[data-nk='button'][href$='/product-resource/new'][data-turbo-frame='_top']",
        text: "New product"
    end

    get_flow("paginated")
    assert_select "#gallery-product-resource-table[data-sort='updated_at'][data-direction='desc'] tbody tr",
      count: 2
    assert_select "#gallery-product-resource-pagination [aria-current='page']", text: "2"
    assert_select "#gallery-product-resource-pagination a[href*='/product-resource/index'][href*='page=1']",
      minimum: 1
  end

  test "new and edit use one toolbar submit and preserve server validation" do
    get_flow("new")
    assert_toolbar_submit("Create product")
    assert_select "#gallery-product-resource-save[disabled]"
    assert_select "#gallery-product-resource-form[method='post'][action='#product-form-demo']"
    assert_select "#gallery-product-resource-form button[type='submit']", count: 0
    assert_select "#product_status option[value='draft'][selected]"
    assert_select "#gallery-product-resource-danger-zone", count: 0

    get_flow("new-validation")
    assert_toolbar_submit("Create product")
    assert_select "#gallery-product-resource-form-error[role='alert'][data-variant='error']"
    assert_select "#gallery-product-resource-form [data-nk='field'][data-state='invalid']", count: 5
    assert_select "#product_name[aria-invalid='true'][value='']"
    assert_select "#product_sku[aria-invalid='true'][value='telemetry']"

    get_flow("edit")
    assert_toolbar_submit("Save product")
    assert_select "#gallery-product-resource-save[disabled]"
    assert_select "#gallery-product-resource-form input[name='_method'][value='patch']"
    assert_select "#product_name[value='Telemetry Hub']"
    assert_select "#gallery-product-resource-danger-zone[data-nk='danger-zone']" do
      assert_select "#gallery-product-resource-delete-dialog[data-nk='dialog']"
      assert_select "#gallery-product-resource-delete-form[data-turbo-frame='_top']" do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button[type='submit'][data-variant='destructive'][disabled]", text: "Delete product"
      end
    end

    get_flow("edit-validation")
    assert_toolbar_submit("Save product")
    assert_select "#gallery-product-resource-form-error[data-variant='error']"
    assert_select "#product_sku[aria-invalid='true'][value='TEL-1']"
    assert_select "#product_price[aria-invalid='true'][value='-29.0']"
    assert_select "#gallery-product-resource-danger-zone[data-nk='danger-zone']"
  end

  test "active archived and history states preserve product lifecycle context" do
    get_flow("active")
    assert_select "#gallery-product-resource-details[data-nk='details-table']" do
      assert_select "table[aria-label='Product metadata'] tbody tr", count: 8
      assert_select "[data-nk='badge'][data-color='success']", text: "Active"
    end
    assert_select "#gallery-product-resource-history-table tbody tr", count: 2
    assert_select "#gallery-product-resource-danger-zone", count: 0

    get_flow("archived")
    assert_select "#gallery-product-resource-archived-alert[data-variant='warning']", text: /New sales are stopped/
    assert_select "#gallery-product-resource-details [data-nk='badge'][data-color='neutral']", text: "Archived"
    assert_select "#gallery-product-resource-history-table tbody tr", count: 1
    assert_select "#gallery-product-resource-danger-zone", count: 0

    get_flow("history")
    assert_select "#gallery-product-resource-history-section[data-nk='data-section']"
    assert_select "#gallery-product-resource-history-table tbody tr", count: 4
    assert_select "#gallery-product-resource-history-table tbody", text: /Created the draft product/

    get gallery_composition_path(
      slug: "product-resource",
      state: "active",
      product_id: "product_release_console"
    )
    assert_response :success
    assert_select "#gallery-product-resource-toolbar h1", text: "Release Console"
    assert_select "#gallery-product-resource-details", text: /REL-042/
    assert_select "#gallery-product-resource-toolbar-actions" do
      assert_select "a[href*='product_id=product_release_console']", count: 2
    end
  end

  test "narrow state uses the same shell and query frame" do
    get_flow("narrow")

    assert_select "#gallery-product-resource-shell[data-gallery-mobile='true'][data-layout='hybrid']"
    assert_select "#gallery-product-resource-toolbar h1", text: "Products"
    assert_select "turbo-frame#gallery-product-resource-query[data-turbo-action='advance']"
    assert_select "#gallery-product-resource-filter-grid[data-cols='1 md:3']"
  end

  private

  def get_flow(state)
    get gallery_composition_path(slug: "product-resource", state:)
    assert_response :success
  end

  def assert_toolbar_submit(label)
    assert_select "#gallery-product-resource-toolbar" do
      assert_select "#gallery-product-resource-save[type='submit']" \
        "[form='gallery-product-resource-form'][data-variant='primary']",
        text: label,
        count: 1
    end
  end
end
