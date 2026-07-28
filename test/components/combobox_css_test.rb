require "test_helper"

class ComboboxCssTest < ActiveSupport::TestCase
  test "active and selected option descriptions keep readable contrast" do
    selector = <<~CSS.strip
      [data-nk="combobox"]
            > [data-slot="combobox-listbox"]
            > [data-slot="combobox-option"]:is(
              [data-active="true"],
              [aria-selected="true"]
            )
            > [data-slot="combobox-option-description"]
    CSS

    assert_includes source_css, selector
    assert_includes bundle_css, selector
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/combobox.css"
    ).read
  end

  def bundle_css
    @bundle_css ||= Rails.root.join(
      "../../app/assets/stylesheets/nitro_kit.css"
    ).read
  end
end
