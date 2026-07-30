require "test_helper"

class RadioButtonGroupCssTest < ActiveSupport::TestCase
  test "a vertical list packs three short options into contiguous comfortable rows" do
    selector = ':where( [data-nk="radio-button-group"][data-presentation="list"][data-orientation="vertical"] ' \
      '> [data-slot="radio-button-group-choices"] )'
    group = Nokogiri::HTML.fragment(
      NitroKit::RadioButtonGroup.new(
        legend: "Density",
        name: "density",
        options: [ "Compact", "Default", "Comfortable" ]
      ).call
    ).first_element_child

    assert_equal 3, group.css("[data-slot='radio-button-group-choice']").size
    assert_match(/#{Regexp.escape(selector)} \{ gap: 0; \}/, squish(source_css))
    assert_includes radio_button_css, "min-block-size: var(--nk-control-height-md)"
  end

  # A segment hides the indicator, so the native radio must stop reserving the
  # space the indicator would have taken: it covers the segment instead, which
  # leaves the label evenly padded between the segment's own paddings.
  test "a segmented radio covers its segment instead of reserving space inside it" do
    rule = ':where( [data-nk="radio-button-group"][data-presentation="segmented"] ' \
      '[data-slot="radio-button-control"] )'

    assert_match(/#{Regexp.escape(rule)} \{ position: absolute; inset: 0;/, squish(source_css))
  end

  test "a segmented label centers its content with no indicator gap" do
    rule = ':where( [data-nk="radio-button-group"][data-presentation="segmented"] ' \
      '[data-slot="radio-button-label"] )'
    declarations = squish(source_css)[/#{Regexp.escape(rule)} \{([^}]*)\}/, 1]

    assert_includes squish(source_css), rule
    assert_includes declarations, "position: relative;"
    assert_includes declarations, "gap: 0;"
    assert_includes declarations, "justify-content: center;"
  end

  private

  def squish(css)
    css.gsub(/\s+/, " ")
  end

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/radio_button_group.css"
    ).read
  end

  def radio_button_css
    @radio_button_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/radio_button.css"
    ).read
  end
end
