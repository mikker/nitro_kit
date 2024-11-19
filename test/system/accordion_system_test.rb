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

  # test("can have multiple items open simultaneously") do
  #   visit "/pages/accordion"
  #
  #   triggers = all("[data-nk--accordion-target='trigger']")
  #
  #   # Open first two items
  #   triggers[0].click
  #   triggers[1].click
  #
  #   # Both should be expanded
  #   assert_equal "true", triggers[0]["aria-expanded"]
  #   assert_equal "true", triggers[1]["aria-expanded"]
  # end
  #
  # test("supports custom trigger content") do
  #   visit "/pages/accordion"
  #
  #   # Find the custom trigger with icon and badge
  #   custom_trigger = find("[data-nk--accordion-target='trigger']", text: /Custom trigger/)
  #
  #   # Verify it contains the expected elements
  #   within(custom_trigger) do
  #     # Icon
  #     assert_selector "[data-nk--icon]"
  #     assert_content "Custom trigger"
  #     # Badge
  #     assert_selector "[data-nk--badge]", text: "OMG"
  #   end
  #
  #   # Verify it works like a regular trigger
  #   custom_trigger.click
  #   assert_equal "true", custom_trigger["aria-expanded"]
  # end
end
