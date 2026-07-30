require "test_helper"

class CheckboxCssTest < ActiveSupport::TestCase
  # A server-rendered error describes the value that was submitted. Once the
  # user has interacted with the control and satisfied its constraints the
  # error is stale, so the danger border is scoped to a control that is not
  # user-valid and the native checked treatment takes over again.
  test "the invalid checkbox border stands down once the control is user-valid" do
    rule = ':where( [data-nk="checkbox"] [data-slot="checkbox-control"][aria-invalid="true"]:not(:user-valid) ' \
      '+ [data-slot="checkbox-indicator"] )'

    css = squish(source_css("checkbox"))
    assert_includes css, rule
    assert_match(/#{Regexp.escape(rule)} \{ border-color: var\(--nk-color-danger\); \}/, css)
  end

  test "the invalid radio border stands down once the control is user-valid" do
    rule = ':where( [data-nk="radio-button"] [data-slot="radio-button-control"][aria-invalid="true"]:not(:user-valid) ' \
      '+ [data-slot="radio-button-indicator"] )'

    css = squish(source_css("radio_button"))
    assert_includes css, rule
    assert_match(/#{Regexp.escape(rule)} \{ border-color: var\(--nk-color-danger\); \}/, css)
  end

  private

  def squish(css)
    css.gsub(/\s+/, " ")
  end

  def source_css(name)
    Rails.root.join("../../src/stylesheets/nitro_kit/components/#{name}.css").read
  end
end
