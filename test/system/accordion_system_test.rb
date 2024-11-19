require "application_system_test_case"

class AccordionSystemTest < ApplicationSystemTestCase
  test("can toggle accordion items") do
    visit "/accordion"

    trigger = find("[data-testid=trigger-1]")
    content = find("[data-testid=content-1]")

    assert_equal "false", trigger["aria-expanded"]
    assert_equal "true", content["aria-hidden"]

    trigger.click

    assert_equal "true", trigger["aria-expanded"]
    assert_equal "false", content["aria-hidden"]

    trigger.click

    assert_equal "false", trigger["aria-expanded"]
    assert_equal "true", content["aria-hidden"]
  end
end
