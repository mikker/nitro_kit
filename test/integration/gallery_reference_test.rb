require "test_helper"

# Every component page must be self-contained for an agent that fetches only
# that page: system rules, the component's own contract, and the patterns it
# belongs to.
class GalleryReferenceTest < ActionDispatch::IntegrationTest
  REFERENCE_ENTRIES = Gallery::Catalog.entries(kind: :component)

  REFERENCE_ENTRIES.each do |entry|
    test "#{entry.kind} #{entry.slug} carries the system rules, its contract, and its patterns" do
      get Gallery::Catalog.path_for(entry, routes: Rails.application.routes.url_helpers)

      assert_response :success

      assert_select "[data-gallery='reference-sections']", count: 1
      assert_select "[data-gallery='reference'][data-gallery-reference='system-rules']", count: 1
      assert_select "[data-gallery='reference'][data-gallery-reference='contract']", count: 1

      contract = Gallery::Contracts.for_entry(entry)
      assert_select "[data-gallery-reference='contract'] [data-gallery='reference-source']",
        text: /NitroKit::#{contract.component}\z/
      assert_predicate contract.fields, :any?
      assert_select "[data-gallery-reference='contract'] [data-gallery='reference-fields'] > div",
        count: contract.fields.size

      patterns = Gallery::Catalog.patterns_for(entry)
      if patterns.any?
        assert_select "[data-gallery-reference='patterns'] [data-gallery='reference-pattern']",
          count: patterns.size
        patterns.each do |pattern|
          assert_select "[data-gallery-pattern='#{pattern.slug}']", count: 1 do
            assert_select "li", count: pattern.points.size
          end
        end
      else
        assert_select "[data-gallery-reference='patterns']", count: 0
      end

      # Page chrome, never example content: the canvas assertions elsewhere stay
      # meaningful only if these sections live outside every canvas.
      assert_select "[data-gallery='example-canvas'] [data-gallery='reference']", count: 0
    end
  end

  test "the system rules name the live reserved attribute vocabulary" do
    get gallery_component_path("button")

    assert_response :success

    rules = css_select("[data-gallery-reference='system-rules'] [data-gallery='reference-rules'] li")
    assert_equal 12, rules.size

    text = rules.map(&:text).join(" ")

    NitroKit::Component::RESERVED_DATA_ATTRIBUTES.each do |name|
      assert_includes text, "data-#{name}"
    end
    NitroKit::Component::ADDITIVE_DATA_ATTRIBUTES.each do |name|
      assert_includes text, "data-#{name}"
    end
    NitroKit::Component::FORBIDDEN_ATTRIBUTES.each do |name|
      assert_includes text, name
    end
    assert_includes text, "RESERVED_DATA_ATTRIBUTES"
    assert_includes text, "desperately_need_a_class:"
  end

  test "contract content is rendered, not summarized" do
    get gallery_component_path("badge")

    assert_response :success

    assert_select "[data-gallery-reference='contract']" do
      assert_select "dt", text: "Root and closed vocabulary"
      assert_select "dd", text: /variants default outline/
      assert_select "code", text: "span[data-nk=badge]"
    end

    get gallery_component_path("danger-zone")

    assert_response :success

    assert_select "[data-gallery-reference='contract'] [data-gallery='reference-source']",
      text: /NitroKit::DangerZone\z/
  end

  test "pattern summaries are inlined on the mapped pages" do
    get gallery_component_path("table")

    assert_response :success

    assert_select "[data-gallery-pattern='queryable_collection']" do
      assert_select "h3", text: "Queryable collection"
      assert_select "li", text: /a stable ID owns filters, sorting, results/
    end

    get gallery_component_path("form-section")

    assert_response :success

    assert_select "[data-gallery-pattern='resource_form'] h3", text: "Resource form"
    assert_select "[data-gallery-pattern='crud_resource'] h3", text: "A complete product resource"
  end
end
