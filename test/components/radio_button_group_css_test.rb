require "test_helper"

class RadioButtonGroupCssTest < ActiveSupport::TestCase
  # A segment hides the indicator, so the native radio must stop reserving the
  # space the indicator would have taken: it covers the segment instead, which
  # leaves the label evenly padded between the segment's own paddings.
  test "a segmented radio covers its segment instead of reserving space inside it" do
    rule = ':where( [data-nk="radio-button-group"][data-presentation="segmented"] ' \
      '[data-slot="radio-button-control"] )'

    assert_includes squish(source_css), rule
    assert_match(/#{Regexp.escape(rule)} \{ position: absolute; inset: 0;/, squish(bundle_css))
  end

  test "a segmented label centers its content with no indicator gap" do
    rule = ':where( [data-nk="radio-button-group"][data-presentation="segmented"] ' \
      '[data-slot="radio-button-label"] )'
    declarations = squish(bundle_css)[/#{Regexp.escape(rule)} \{([^}]*)\}/, 1]

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

  def bundle_css
    @bundle_css ||= Rails.root.join(
      "../../app/assets/stylesheets/nitro_kit.css"
    ).read
  end
end
