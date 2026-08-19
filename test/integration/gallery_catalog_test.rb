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

        assert_empty nitro_owned("[data-gallery='example-canvas'] [class]")
        assert_empty nitro_owned("[data-gallery='example-canvas'] [style]")
        assert_empty nitro_owned("[data-gallery='example-canvas'] [data-nk-escape]")

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
        assert_owned_form_rhythm(entry, state)
      end
    end
  end

  private

  # Nitro never emits classes or styles, but application content slots such as
  # the rich-text editor region carry the host editor's own markup.
  APPLICATION_OWNED_SLOTS = "[data-slot='rich-text-area-editor']"
  SPACING_OWNERS = %w[field-group flex grid fieldset].freeze

  def nitro_owned(selector)
    document.css(selector).reject do |node|
      %w[color-chip depth-chip measure-bar motion-chip radius-chip type-chip].include?(node["data-gallery"]) ||
        node.ancestors(APPLICATION_OWNED_SLOTS).any?
    end.map { |node| node.name }
  end

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

  def assert_owned_form_rhythm(entry, state)
    document.css("form").each do |form|
      ([ form ] + form.css("*").to_a).each do |parent|
        stacked = parent.element_children.select { |node| field?(node) || submit_button?(node) }

        next if stacked.count { |node| field?(node) }.zero?
        next if stacked.size < 2
        next if SPACING_OWNERS.include?(parent["data-nk"])

        flunk <<~MESSAGE
          #{entry.kind} page "#{entry.slug}"#{" (state #{state})" if state}, example "#{example_slug(form)}":
          #{stacked.size} stacked controls (#{stacked.map { |node| node["data-nk"] }.join(", ")}) are direct
          siblings inside <#{parent.name}#{" data-nk=\"#{parent["data-nk"]}\"" if parent["data-nk"]}#{" id=\"#{parent["id"]}\"" if parent["id"]}>,
          which owns no gap, so they stack flush against each other.
          Wrap them in NitroKit::FieldGroup (or form.group inside a form_with block);
          use Flex or Grid when the arrangement is deliberately inline or multi-column.
          Form: #{form["id"] || "(no id)"}
        MESSAGE
      end
    end
  end

  def field?(node)
    node["data-nk"] == "field" || node["data-nk"] == "dropzone"
  end

  def submit_button?(node)
    node["data-nk"] == "button" && node["type"] == "submit"
  end

  def example_slug(node)
    node.ancestors("[data-gallery='example']").first&.[]("data-gallery-example") || "(unknown)"
  end

  def document
    @document ||= Nokogiri::HTML5(response.body)
  end
end
