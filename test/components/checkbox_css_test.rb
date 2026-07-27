require "test_helper"

class CheckboxCssTest < ActiveSupport::TestCase
  # A server-rendered error describes the value that was submitted. Once the
  # user has interacted with the control and satisfied its constraints the
  # error is stale, so the danger border is scoped to a control that is not
  # user-valid and the native checked treatment takes over again.
  test "the invalid checkbox border stands down once the control is user-valid" do
    rule = ':where( [data-nk="checkbox"] [data-slot="checkbox-control"][aria-invalid="true"]:not(:user-valid) ' \
      '+ [data-slot="checkbox-indicator"] )'

    assert_includes squish(source_css("checkbox")), rule
    assert_includes squish(bundle_css), rule
    assert_match(/#{Regexp.escape(rule)} \{ border-color: var\(--nk-color-danger\); \}/, squish(bundle_css))
  end

  test "the invalid radio border stands down once the control is user-valid" do
    rule = ':where( [data-nk="radio-button"] [data-slot="radio-button-control"][aria-invalid="true"]:not(:user-valid) ' \
      '+ [data-slot="radio-button-indicator"] )'

    assert_includes squish(source_css("radio_button")), rule
    assert_includes squish(bundle_css), rule
    assert_match(/#{Regexp.escape(rule)} \{ border-color: var\(--nk-color-danger\); \}/, squish(bundle_css))
  end

  private

  def squish(css)
    css.gsub(/\s+/, " ")
  end

  def source_css(name)
    Rails.root.join("../../src/stylesheets/nitro_kit/components/#{name}.css").read
  end

  def bundle_css
    @bundle_css ||= Rails.root.join("../../app/assets/stylesheets/nitro_kit.css").read
  end
end
