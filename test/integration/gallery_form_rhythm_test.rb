require "test_helper"

# Vertical rhythm between stacked fields is owned by a spacing parent, never by
# the fields themselves. Two Fields — or a Field and its submit Button — that
# are direct siblings under a bare `form` or an ordinary `div` stack with no
# gap at all. `FieldGroup` (`form.group`) is the default owner; `Flex`, `Grid`,
# and `Fieldset` own placement for inline and multi-column arrangements.
#
# Single-field forms are fine, and so is a lone submit, because neither needs a
# gap. The rule only fires once a field genuinely has a spacing-bearing sibling.
class GalleryFormRhythmTest < ActionDispatch::IntegrationTest
  # Parents that own the gap between the controls they contain.
  SPACING_OWNERS = %w[field-group flex grid fieldset].freeze

  Gallery::Catalog.entries.reject { |entry| entry.kind == :home }.each do |entry|
    states = entry.states.any? ? entry.states : [ nil ]

    states.each do |state|
      test "#{entry.kind} #{entry.slug}#{" in #{state}" if state} owns the rhythm between stacked fields" do
        get Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )

        assert_response :success

        bare_stacks(entry, state).each do |failure|
          flunk failure
        end
      end
    end
  end

  private

  def bare_stacks(entry, state)
    document.css("form").flat_map do |form|
      ([ form ] + form.css("*").to_a).filter_map do |parent|
        stacked = stacked_controls(parent)

        next if stacked.count { |node| field?(node) }.zero?
        next if stacked.size < 2
        next if SPACING_OWNERS.include?(parent["data-nk"])

        failure_message(entry, state, form, parent, stacked)
      end
    end
  end

  # A field paired with another field or with the form's submit needs a gap
  # between them; anything else in the form is not this rule's business.
  def stacked_controls(parent)
    parent.element_children.select { |node| field?(node) || submit_button?(node) }
  end

  # A Dropzone is a field in every way that matters here: it is a labelled
  # control that owns no placement of its own.
  def field?(node)
    node["data-nk"] == "field" || node["data-nk"] == "dropzone"
  end

  def submit_button?(node)
    node["data-nk"] == "button" && node["type"] == "submit"
  end

  def failure_message(entry, state, form, parent, stacked)
    <<~MESSAGE
      #{entry.kind} page "#{entry.slug}"#{" (state #{state})" if state}, example "#{example_slug(form)}":
      #{stacked.size} stacked controls (#{stacked.map { |node| node["data-nk"] }.join(", ")}) are direct
      siblings inside <#{parent.name}#{" data-nk=\"#{parent["data-nk"]}\"" if parent["data-nk"]}#{" id=\"#{parent["id"]}\"" if parent["id"]}>,
      which owns no gap, so they stack flush against each other.
      Wrap them in NitroKit::FieldGroup (or form.group inside a form_with block);
      use Flex or Grid when the arrangement is deliberately inline or multi-column.
      Form: #{form["id"] || "(no id)"}
    MESSAGE
  end

  def example_slug(node)
    node.ancestors("[data-gallery='example']").first&.[]("data-gallery-example") || "(unknown)"
  end

  def document
    @document ||= Nokogiri::HTML5(response.body)
  end
end
