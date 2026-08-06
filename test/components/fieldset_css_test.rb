require "test_helper"

class FieldsetCssTest < ActiveSupport::TestCase
  test "direct actions keep their intrinsic width" do
    assert_match(
      /\[data-nk="fieldset"\].*\[data-slot="fieldset-fields"\].*\[data-nk="button"\].*justify-self: start;/m,
      source_css
    )
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/fieldset.css"
    ).read
  end
end
