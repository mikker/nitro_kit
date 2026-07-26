require "application_system_test_case"

class InteractiveComponentsTest < ApplicationSystemTestCase
  test "accordion uses native keyboard disclosure and single-group exclusivity" do
    path = visit_component("accordion")

    assert_selector "#gallery-accordion-billing details[name='gallery-accordion-billing']", count: 3
    assert_selector "#gallery-accordion-billing [data-key='invoices'][open]"

    find("#gallery-accordion-billing-currency-trigger").send_keys(:space)

    assert_selector "#gallery-accordion-billing [data-key='currency'][open]"
    assert_selector "#gallery-accordion-billing-currency-content", visible: true
    assert_selector "#gallery-accordion-billing [data-key='invoices']:not([open])", visible: :all
    assert_selector "#gallery-accordion-billing-invoices-content", visible: false

    find("#gallery-accordion-billing-currency-trigger").send_keys(:enter)

    assert_selector "#gallery-accordion-billing [data-key='currency']:not([open])", visible: :all
    assert_selector "#gallery-accordion-billing-currency-content", visible: false
    assert_selector "#gallery-accordion-billing-legacy-trigger", visible: true
    assert_no_severe_console_errors(context: path)
  end

  test "tabs support automatic and manual keyboard activation while skipping disabled tabs" do
    path = visit_component("tabs")

    find("#gallery-tabs-settings-members-tab").send_keys(:arrow_right)

    assert_focused "#gallery-tabs-settings-billing-tab"
    assert_selector "#gallery-tabs-settings-billing-tab[aria-selected='true'][tabindex='0']"
    assert_selector "#gallery-tabs-settings-billing-panel[aria-hidden='false']:not([hidden])"

    find("#gallery-tabs-settings-billing-tab").send_keys(:home)

    assert_focused "#gallery-tabs-settings-general-tab"
    assert_selector "#gallery-tabs-settings-general-tab[aria-selected='true']"

    find("#gallery-tabs-vertical-manual-security-tab").send_keys(:arrow_down, :arrow_down)

    assert_focused "#gallery-tabs-vertical-manual-profile-tab"
    assert_selector "#gallery-tabs-vertical-manual-security-tab[aria-selected='true']"
    assert_selector "#gallery-tabs-vertical-manual-profile-tab[aria-selected='false'][tabindex='0']"
    assert_selector "#gallery-tabs-vertical-manual-legacy-tab[disabled][tabindex='-1']", visible: :all

    find("#gallery-tabs-vertical-manual-profile-tab").send_keys(:end, :enter)

    assert_focused "#gallery-tabs-vertical-manual-notifications-tab"
    assert_selector "#gallery-tabs-vertical-manual-notifications-tab[aria-selected='true']"
    assert_selector "#gallery-tabs-vertical-manual-notifications-panel[aria-hidden='false']:not([hidden])"
    assert_no_severe_console_errors(context: path)
  end

  test "dialog manages native focus escape dismissal close controls and disabled triggers" do
    path = visit_component("dialog")
    root = "#gallery-dialog-remove-member"
    trigger = "#{root} [data-slot='dialog-trigger']"
    panel = "#{root} [data-slot='dialog-panel']"
    close = "#{root} [data-slot='dialog-close']"

    find(trigger).click

    assert_selector "#{panel}[open]"
    assert_focused close

    active_element.send_keys(:escape)

    assert_selector "#{panel}:not([open])", visible: :all
    assert_focused trigger

    find(trigger).click
    find(close).click

    assert_selector "#{panel}:not([open])", visible: :all
    assert_selector "#gallery-dialog-disabled [data-slot='dialog-trigger'][disabled]:not([command])", visible: :all
    assert_selector "#gallery-dialog-disabled [data-slot='dialog-panel']:not([open])", visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "dropdown follows menu keyboard focus and closes on escape tab and selection" do
    path = visit_component("dropdown")
    root = "#gallery-dropdown-account"
    trigger = "#{root}-trigger"
    content = "#{root}-content"
    settings = "#{content} a[href='/gallery/settings']"
    duplicate = "#{content} button[data-slot='dropdown-item']"
    delete = "#{content} button[data-variant='destructive']"

    find(trigger).send_keys(:arrow_down)

    assert_selector "#{content}:popover-open"
    assert_focused settings

    find(settings).send_keys(:end)
    assert_focused delete

    find(delete).send_keys(:arrow_up)
    assert_focused duplicate, text: "Duplicate workspace"

    find(duplicate, text: "Duplicate workspace").send_keys(:home)
    assert_focused settings

    find(settings).send_keys(:escape)

    assert_selector "#{content}:not(:popover-open)", visible: :all
    assert_focused trigger

    find(trigger).send_keys(:arrow_up)
    assert_focused delete
    find(delete).send_keys(:tab)

    assert_selector "#{content}:not(:popover-open)", visible: :all

    find(trigger).send_keys(:arrow_down)
    find(settings).send_keys(:arrow_down)
    assert_focused duplicate, text: "Duplicate workspace"
    active_element.send_keys(:enter)

    assert_selector "#{content}:not(:popover-open)", visible: :all
    assert_selector "#gallery-dropdown-disabled-trigger[disabled]:not([popovertarget])", visible: :all
    assert_selector "#gallery-dropdown-disabled:not([data-state])"
    assert_no_severe_console_errors(context: path)
  end

  test "tooltip opens for focus and pointer intent and closes on escape and pointer leave" do
    path = visit_component("tooltip")
    root = "#gallery-tooltip-primary"
    trigger = "#{root}-trigger"
    content = "#{root}-content"

    execute_script("arguments[0].focus()", find(trigger))

    assert_focused trigger
    assert_equal "visible", evaluate_script("getComputedStyle(arguments[0]).visibility", find(content, visible: :all))

    find(trigger).send_keys(:escape)

    assert_focused trigger
    assert_selector "#{root}[data-dismissed]"
    assert_equal "hidden", evaluate_script("getComputedStyle(arguments[0]).visibility", find(content, visible: :all))

    find("[data-gallery='brand']").hover
    execute_script("arguments[0].blur()", find(trigger))
    assert_selector "#{root}:not([data-dismissed])"
    find(trigger).hover
    assert_equal "visible", evaluate_script("getComputedStyle(arguments[0]).visibility", find(content, visible: :all))
    find("[data-gallery='brand']").hover

    assert_equal "hidden", evaluate_script("getComputedStyle(arguments[0]).visibility", find(content, visible: :all))
    assert_no_severe_console_errors(context: path)
  end

  test "combobox commits keyboard selection and preserves submitted value validity and availability" do
    path = visit_component("combobox")
    root = "#gallery-combobox-empty"
    input = "#{root}-input"
    value = "#{root}-value"

    find(input).click
    find(input).send_keys(:end)

    assert_selector "#{root}[data-state='open']"
    assert_selector "#{input}[aria-activedescendant='gallery-combobox-empty-option-5']"

    find(input).send_keys(:enter)

    assert_focused input
    assert_equal "Iceland", find(input).value
    assert_equal "is", find(value, visible: :all).value
    assert_selector "#{root}[data-state='closed']"
    assert_selector "#{root}-option-5[aria-selected='true']", visible: :all

    find(input).set("Finland")

    assert_equal "", find(value, visible: :all).value
    assert_selector "#{input}[aria-invalid='true']"
    assert_selector "#{root} [data-value='fi'][aria-disabled='true']:not([hidden])"
    find(input).send_keys(:enter, :escape)
    assert_equal "", find(value, visible: :all).value
    assert_selector "#{root}[data-state='closed']"

    required = "#gallery-combobox-required-input"
    required_value = "#gallery-combobox-required-value"
    assert_selector "#{required}[aria-required='true'][aria-invalid='true']:not([required])"

    find(required).set("Denmark")

    assert_selector "#{required}[aria-invalid='false']"
    assert_equal "dk", find(required_value, visible: :all).value
    assert_selector "#gallery-combobox-disabled-input[disabled]", visible: :all
    assert_selector "#gallery-combobox-disabled-value[disabled]", visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "switch keeps native keyboard checked submission required and disabled semantics" do
    path = visit_component("switch")
    control = "#gallery-switch-medium-control"

    assert_selector "#{control}:not(:checked)", visible: :all
    assert_equal "0", find("input[type='hidden'][name='preferences[weekly_digest]']", visible: :all).value

    execute_script("arguments[0].focus()", find(control, visible: :all))
    assert_focused control, visible: :all
    active_element.send_keys(:space)

    assert_selector "#{control}:checked", visible: :all
    assert_equal "1", find(control, visible: :all).value

    find("label[for='gallery-switch-medium-control']", text: "Weekly digest").click

    assert_selector "#{control}:not(:checked)", visible: :all

    required = find("#gallery-switch-required-control", visible: :all)
    execute_script("arguments[0].focus()", required)
    active_element.send_keys(:space)
    assert_not evaluate_script("arguments[0].checkValidity()", required)
    active_element.send_keys(:space)
    assert evaluate_script("arguments[0].checkValidity()", required)

    disabled = "#gallery-switch-disabled-control"
    assert_selector "#{disabled}[disabled]:checked", visible: :all
    find("label[for='gallery-switch-disabled-control']", text: "Legacy synchronization").click
    assert_selector "#{disabled}:checked", visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "date input exposes native value range required readonly and disabled behavior" do
    path = visit_component("input")
    required = find("#gallery-input-date-required")

    set_native_value(required, "")
    assert evaluate_script("arguments[0].validity.valueMissing", required)

    set_native_value(required, "2026-07-12")
    assert evaluate_script("arguments[0].validity.rangeUnderflow", required)

    set_native_value(required, "2026-07-20")
    assert_equal "2026-07-20", required.value
    assert evaluate_script("arguments[0].checkValidity()", required)

    assert_field "gallery-input-date-selected", with: "2026-07-13", type: :date
    assert_selector "#gallery-input-date-readonly[readonly][value='2026-07-13']"
    assert_selector "#gallery-input-date-disabled[disabled][value='2026-07-13']", visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "toast visibly pauses resumes auto-dismisses and supports explicit dismissal" do
    path = visit_component("toast")
    root = "#gallery-toast-integration-result"
    item = "#{root} [data-nk='toast-item']"
    timed_item = "#gallery-toast-timed [data-nk='toast-item']"
    timed_dismiss = "#{timed_item} [data-slot='toast-item-dismiss']"

    # The timed sample starts counting down as soon as its controller connects,
    # so focus has to be the first interaction on the page.
    execute_script("arguments[0].focus()", find(timed_dismiss))

    assert_focused timed_dismiss
    sleep 1.4
    assert_selector "#{timed_item}[data-state='open']"

    assert_selector "#gallery-toast-permanent [data-nk='toast-item']"
    assert_no_selector "#gallery-toast-permanent [data-slot='toast-item-dismiss']"

    execute_script("arguments[0].focus()", find("[data-gallery='brand'] a"))
    assert_no_selector timed_item, wait: 2.5

    find("#{item} [data-slot='toast-item-dismiss']").click

    assert_no_selector item
    assert_no_severe_console_errors(context: path)
  end

  private
    def visit_component(slug)
      path = gallery_component_path(slug)
      visit path

      assert_current_path path
      assert_selector "div[data-gallery='page'][data-gallery-page='#{slug}']"
      path
    end

    def set_native_value(element, value)
      execute_script(<<~JAVASCRIPT, element, value)
        arguments[0].value = arguments[1]
        arguments[0].dispatchEvent(new Event("input", { bubbles: true }))
        arguments[0].dispatchEvent(new Event("change", { bubbles: true }))
      JAVASCRIPT
    end
end
