require "application_system_test_case"

class ControlGroupSystemTest < ApplicationSystemTestCase
  test "groups preserve large buttons and stretch smaller controls including dates to match" do
    visit gallery_component_path("control-group")

    assert_group_heights "#gallery-control-group-size-sm", group: 40, input: 40, button: 40
    assert_group_heights "#gallery-control-group-size-lg", group: 44, select: 44, addon: 44, button: 44
    xl_group = "#gallery-control-group-size-xl"
    assert_equal "date", find("#{xl_group} > [data-nk='input']")[:type]
    assert_group_heights xl_group, group: 56, input: 56, addon: 56, button: 56
    assert_in_delta 54, date_line_height(xl_group), 0.01
    assert_no_severe_console_errors(context: "ControlGroup intrinsic heights")
  end

  private

  def assert_group_heights(selector, **expected)
    actual = evaluate_script(<<~JAVASCRIPT, find(selector))
      (() => {
        const group = arguments[0]
        const input = group.querySelector(":scope > [data-nk='input']")
        const height = (element) => element && parseFloat(getComputedStyle(element).height)

        return {
          group: height(group),
          input: height(input),
          select: height(group.querySelector(":scope > [data-nk='select'] > select")),
          addon: height(group.querySelector(":scope > [data-slot='control-group-addon']")),
          button: height(group.querySelector(":scope > [data-nk='button']"))
        }
      })()
    JAVASCRIPT

    expected.each do |part, height|
      assert_in_delta height, actual.fetch(part.to_s), 0.01, "#{selector} #{part} height"
    end
  end

  def date_line_height(selector)
    evaluate_script(<<~JAVASCRIPT, find("#{selector} > [data-nk='input'][type='date']"))
      parseFloat(getComputedStyle(arguments[0]).lineHeight)
    JAVASCRIPT
  end
end
