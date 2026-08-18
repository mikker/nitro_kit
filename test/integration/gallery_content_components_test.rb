require "test_helper"

class GalleryContentComponentsTest < ActionDispatch::IntegrationTest
  SLUGS = %w[page-header stat-grid data-section settings-section danger-zone empty-state].freeze

  test "catalog exposes the six content and form component routes" do
    entries = SLUGS.map { |slug| Gallery::Catalog.fetch!(kind: :component, slug:) }

    assert_equal SLUGS, entries.map(&:slug)
    assert_equal(
      %i[application data application application application feedback],
      entries.map(&:subcategory)
    )
    assert_equal(
      SLUGS.map { |slug| "/gallery/components/#{slug}" },
      entries.map { |entry| Gallery::Catalog.path_for(entry, routes: Rails.application.routes.url_helpers) }
    )
  end

  test "every content component page is class-free direct Phlex in light and dark themes" do
    SLUGS.each do |slug|
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

  test "page header gallery covers optional copy grouped actions long content and nesting" do
    get_block("page-header")

    assert_select "#gallery-page-header-title-only" do
      assert_select "> [data-slot='page-header-title']", count: 1
      assert_select "> [data-slot='page-header-eyebrow']", count: 0
      assert_select "> [data-slot='page-header-description']", count: 0
      assert_select "> [data-slot='page-header-actions']", count: 0
    end
    assert_select "#gallery-page-header-complete > [data-slot='page-header-actions'][data-nk='button-group']"
    assert_select "#gallery-page-header-long", text: /International Research, Production, and Reliability Engineering/
    assert_select "#gallery-page-header-container > #gallery-page-header-nested[data-nk='page-header']"
    assert_select "#gallery-page-header-compound > h2[data-slot='page-header-title'] strong", text: "Analytical Engines"
    assert_select "#gallery-page-header-compound > [data-slot='page-header-description'] time", count: 1
  end

  test "stat grid gallery covers one partial complete dense long and nested records" do
    get_block("stat-grid")

    assert_select "#gallery-stat-grid-one [data-slot='stat-grid-stat']", count: 1
    assert_select "#gallery-stat-grid-two [data-slot='stat-grid-stat']", count: 2
    assert_select "#gallery-stat-grid-three [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-stat-grid-dense [data-slot='stat-grid-stat']", count: 9
    assert_select "#gallery-stat-grid-long-container > #gallery-stat-grid-long[data-nk='stat-grid']"
    assert_select "[data-nk='stat-grid'] > [data-nk='grid'][data-cols='1 sm:2 lg:3']", minimum: 1
  end

  test "data section gallery covers table empty action dense and nested contracts" do
    get_block("data-section")

    assert_select "#gallery-data-section-minimal > [data-slot='data-section-table'][data-nk='table']"
    assert_select "#gallery-data-section-complete > [data-slot='data-section-header'] [data-slot='data-section-actions'][data-nk='button-group']"
    assert_select "#gallery-data-section-empty > [data-slot='data-section-empty-state'][data-nk='empty-state']" do
      assert_select "h3[data-slot='empty-state-title']"
    end
    assert_select "#gallery-data-section-dense-table [data-slot='table-row']", minimum: 13
    assert_select "[data-nk='data-section'] + [data-nk='pagination']", count: 0
  end

  test "form section gallery owns status ordering around complete Rails forms" do
    get_block("settings-section")

    assert_select "#gallery-settings-section-minimal > [data-slot='settings-section-form'] > form", count: 1
    assert_select "#gallery-settings-section-validation" do
      assert_select "> [data-slot='settings-section-status'][data-nk='alert'][data-variant='destructive']"
      assert_select "> [data-slot='settings-section-form'] > form#gallery-settings-section-validation-form"
    end
    assert_select "#gallery-settings-section-success > [data-slot='settings-section-status'][data-variant='success']"
    assert_select "#gallery-settings-section-dense [data-nk='field']", count: 5
  end

  test "danger zone gallery keeps confirmation composition and safe escape distinct" do
    get_block("danger-zone")

    assert_select "[data-nk='danger-zone']", count: 5 do |zones|
      assert zones.all? { |zone| zone.at_css("[data-slot='danger-zone-confirmation']") }
      assert zones.all? { |zone| zone.at_css("[data-slot='danger-zone-description']") }
      assert zones.none? { |zone| zone.at_css("[data-slot='danger-zone-escape'][data-variant='destructive']") }
    end
    assert_select "#gallery-danger-zone-no-escape [data-slot='danger-zone-escape']", count: 0
    assert_select "#gallery-danger-zone-disabled-form[data-nk='button-to'] " \
                  "[data-variant='destructive'][disabled]"
    assert_select "#gallery-danger-zone-dialog [data-slot='danger-zone-confirmation'] [data-nk='dialog']"
    assert_select "#gallery-danger-zone-no-escape-form[data-nk='button-to']"
    assert_select "#gallery-danger-zone-long-form[data-nk='button-to']"
    assert_select "#gallery-danger-zone-long-container > #gallery-danger-zone-long"
  end

  test "empty state gallery covers heading levels optional content and bounded actions" do
    get_block("empty-state")

    assert_select "#gallery-empty-state-title-only" do
      assert_select "> h2[data-slot='empty-state-title']"
      assert_select "> [data-slot='empty-state-icon']", count: 0
      assert_select "> [data-slot='empty-state-description']", count: 0
      assert_select "> [data-slot='empty-state-actions']", count: 0
    end
    assert_select "#gallery-empty-state-information > [data-slot='empty-state-icon'][data-nk='icon']"
    assert_select "#gallery-empty-state-one-action [data-slot='empty-state-action']", count: 1
    assert_select "#gallery-empty-state-two-actions [data-slot='empty-state-action']", count: 2
    assert_select "#gallery-empty-state-long > h4[data-slot='empty-state-title'] > strong"
    assert_select "#example-empty-state-long-code [data-gallery='code-source']", text: /empty\.title/
  end

  test "empty state gallery documents the borderless variant and when to prefer it" do
    get_block("empty-state")

    assert_select "#gallery-empty-state-variant-default[data-variant='default']"
    assert_select "#gallery-empty-state-variant-borderless[data-variant='borderless']"
    assert_select "#section-empty-state-presentation-description", text: /Dropzone/
    assert_select "#gallery-empty-state-card[data-nk='card']" do
      assert_select "#gallery-empty-state-in-card[data-variant='borderless'] > h4[data-slot='empty-state-title']"
    end
  end

  private

  def get_block(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
