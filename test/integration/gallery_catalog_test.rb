require "test_helper"

class GalleryCatalogTest < ActionDispatch::IntegrationTest
  Gallery::Catalog.entries.reject { |entry| entry.kind == :home }.each do |entry|
    states = entry.states.any? ? entry.states : [ nil ]

    states.each do |state|
      test "renders #{entry.kind} #{entry.slug}#{" in #{state}" if state}" do
        path = Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )

        get(path)

        assert_response :success
        assert_select "html[data-gallery='document']"
        assert_select "div[data-gallery='page'][data-gallery-page='#{entry.slug}']"
        assert_predicate entry.expected_roots, :any?

        assert_select(
          "[data-gallery='example-canvas'] [data-nk='#{entry.expected_roots.first}'][id]",
          minimum: 1
        )

        entry.expected_roots.each do |root|
          assert_select "[data-gallery='example-canvas'] [data-nk='#{root}']", minimum: 1
        end

        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0

        assert_select "[data-gallery='example']", minimum: 1 do |examples|
          examples.each do |example|
            assert_select example, "[data-gallery='example-tabs'][data-nk='tabs']", count: 1
            assert_select example, "[role='tab']", text: "Preview", count: 1
            assert_select example, "[role='tab']", text: "Code", count: 1
            assert_select example, "[data-gallery='code-sample']", count: 1 do
              assert_select "[data-gallery='code-path']", text: /\.rb\z/, count: 1
              assert_select "[data-gallery='code-source']", minimum: 1 do |sources|
                assert_predicate sources.first.text, :present?
              end
              assert_select "script", count: 0
              assert_select "[class]", count: 0
              assert_select "[style]", count: 0
            end
          end
        end

        assert_unique_ids
        assert_valid_id_references
      end
    end
  end

  private

  def assert_unique_ids
    ids = document.css("[id]").map { |node| node["id"] }
    duplicates = ids.tally.select { |_id, count| count > 1 }

    assert_empty duplicates, "duplicate document IDs: #{duplicates.inspect}"
  end

  def assert_valid_id_references
    ids = document.css("[id]").map { |node| node["id"] }.to_set
    id_references = document.css(
      "[aria-activedescendant], [aria-controls], [aria-describedby], [aria-labelledby], [aria-owns], label[for]"
    ).flat_map do |node|
      %w[aria-activedescendant aria-controls aria-describedby aria-labelledby aria-owns for].flat_map do |attribute|
        node[attribute].to_s.split
      end
    end
    missing = id_references.to_set - ids

    assert_empty missing, "references to missing document IDs: #{missing.to_a.sort.inspect}"
  end

  def document
    @document ||= Nokogiri::HTML5(response.body)
  end
end
