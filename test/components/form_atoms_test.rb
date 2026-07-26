require "test_helper"

class FormAtomsTest < ActiveSupport::TestCase
  test "label owns native attributes and requires content" do
    node = render_node(
      NitroKit::Label.new(
        "Email",
        for: "email",
        id: "email-label",
        html: { title: "Account email" },
        aria: { hidden: false },
        data: { tracking_id: "email" }
      )
    )

    assert_equal "label", node.name
    assert_equal "label", node["data-nk"]
    assert_equal "email", node["for"]
    assert_equal "false", node["aria-hidden"]
    assert_equal "email", node["data-tracking-id"]
    assert_empty node.css("[class], [style]")
    assert_raises(ArgumentError) { NitroKit::Label.new.call }
    assert_raises(ArgumentError) { NitroKit::Label.new("") }
    assert_raises(ArgumentError) { NitroKit::Label.new("Email", html: { class: "bad" }) }
  end

  test "textarea renders value as escaped content and validates native constraints" do
    node = render_node(
      NitroKit::Textarea.new(
        id: "bio",
        name: "profile[bio]",
        value: "<b>Hello</b>",
        required: true,
        readonly: true,
        rows: 4,
        cols: 30,
        minlength: 2,
        maxlength: 100,
        wrap: :hard
      )
    )

    assert_equal "textarea", node.name
    assert_equal "textarea", node["data-nk"]
    assert_equal "<b>Hello</b>", node.text
    assert_equal "4", node["rows"]
    assert_equal "hard", node["wrap"]
    assert node.key?("required")
    assert node.key?("readonly")
    assert_empty node.css("[class], [style]")

    assert_raises(ArgumentError) { NitroKit::Textarea.new(rows: 0) }
    assert_raises(ArgumentError) { NitroKit::Textarea.new(minlength: 4, maxlength: 2) }
    assert_raises(ArgumentError) { NitroKit::Textarea.new(wrap: :sometimes) }
    assert_raises(ArgumentError) { NitroKit::Textarea.new(wrap: false) }
    assert_raises(ArgumentError) { NitroKit::Textarea.new(wrap: 1) }
    owned = assert_raises(ArgumentError) { NitroKit::Textarea.new(html: { rows: 4 }) }
    assert_equal "rows is owned by Textarea; pass rows: as a keyword", owned.message
    assert_raises(ArgumentError) { NitroKit::Textarea.new(html: { value: "bypass" }) }
    assert_equal "4", render_node(NitroKit::Textarea.new(html: { title: "Bio" }, rows: 4))["rows"]
    assert_raises(ArgumentError) { NitroKit::Textarea.new(disabled: nil) }
  end

  test "choice records reject malformed and misspelled options" do
    choice = NitroKit::Choice.coerce(label: "Admin", value: "admin", disabled: true, id: "role-admin")

    assert_instance_of NitroKit::Choice, choice
    assert choice.frozen?
    assert choice.disabled
    assert_equal "role-admin", choice.id
    assert_raises(ArgumentError) { NitroKit::Choice.coerce(label: "Admin", value: "admin", disabeld: true) }
    assert_raises(ArgumentError) { NitroKit::Choice.coerce(label: "", value: "admin") }
    assert_raises(ArgumentError) { NitroKit::Choice.coerce(label: "Admin", value: nil) }
    assert_raises(ArgumentError) { NitroKit::Choice.coerce([ "Admin", "admin", false ]) }
    assert_raises(ArgumentError) { NitroKit::Choice.coerce([ "Admin", "admin", false, "role-admin" ]) }
  end

  test "select uses typed options selected arrays and native multiple naming" do
    node = render_node(
      NitroKit::Select.new(
        options: [
          [ "Developer", "developer" ],
          { label: "Designer", value: "designer", disabled: true, id: "role-designer" }
        ],
        id: "roles",
        name: "account[roles]",
        value: %w[developer designer],
        multiple: true,
        required: true,
        control_data: { tracking_id: "roles" }
      )
    )
    control = node.at_css("select")

    assert_equal "select", node["data-nk"]
    assert_equal "select-control", control["data-slot"]
    assert_equal "account[roles][]", control["name"]
    assert control.key?("multiple")
    assert control.key?("required")
    assert_equal %w[developer designer], control.css("option[selected]").map { |option| option["value"] }
    assert control.at_css("option[value='designer']").key?("disabled")
    assert_equal "role-designer", control.at_css("option[value='designer']")["id"]
    assert_equal "roles", control["data-tracking-id"]
    assert_nil node.at_css("svg")
    assert_empty node.css("[class], [style]")
  end

  test "select distinguishes persistent blanks from conditional prompts" do
    blank = render_node(
      NitroKit::Select.new(options: [ [ "Admin", "admin" ] ], value: "admin", include_blank: "None")
    )
    selected = render_node(
      NitroKit::Select.new(options: [ [ "Admin", "admin" ] ], value: "admin", prompt: "Choose a role")
    )
    unselected = render_node(
      NitroKit::Select.new(options: [ [ "Admin", "admin" ] ], prompt: "Choose a role")
    )

    assert_equal "None", blank.at_css("option:first-child").text
    assert_nil selected.at_css("option[value='']")
    assert_equal "Choose a role", unselected.at_css("option[value='']").text
    refute unselected.at_css("option[value='']").key?("disabled")
    assert_raises(ArgumentError) { NitroKit::Select.new(include_blank: 1) }
    assert_raises(ArgumentError) { NitroKit::Select.new(prompt: " ") }
    both = assert_raises(ArgumentError) do
      NitroKit::Select.new(options: [ [ "Admin", "admin" ] ], include_blank: true, prompt: "Choose")
    end
    assert_equal "include_blank: and prompt: are mutually exclusive", both.message
  end

  test "select separates its inner control identity from its root" do
    node = render_node(
      NitroKit::Select.new(
        options: [ [ "Admin", "admin" ] ],
        id: "role-control",
        html: { id: "role-wrapper" }
      )
    )

    assert_equal "role-wrapper", node["id"]
    assert_equal "role-control", node.at_css("select")["id"]
    assert node.at_css("[data-slot='select-icon']")
  end

  test "select accepts only trusted captured option markup" do
    option_tags = '<option value="admin">Admin</option>'.html_safe
    node = render_node(NitroKit::Select.new(option_tags:, value: "admin"))

    assert_equal "Admin", node.at_css("option").text
    assert_raises(ArgumentError) { NitroKit::Select.new(option_tags: "<option>Unsafe</option>") }
    assert_raises(ArgumentError) do
      NitroKit::Select.new(options: [ "Admin" ], option_tags:)
    end
  end

  test "checkbox submits checked and unchecked values with deterministic identity" do
    node = render_node(
      NitroKit::Checkbox.new(
        label: "Accept terms",
        id: "terms",
        name: "account[terms]",
        value: "yes",
        unchecked_value: "no",
        checked: true,
        required: true
      )
    )
    hidden = node.at_css("input[type='hidden']")
    control = node.at_css("input[type='checkbox']")

    assert_equal "checkbox", node["data-nk"]
    assert_equal "account[terms]", hidden["name"]
    assert_equal "no", hidden["value"]
    assert_equal "yes", control["value"]
    assert_equal "terms", control["id"]
    assert control.key?("checked")
    assert control.key?("required")
    assert_equal "terms", node.at_css("label")["for"]
    assert_equal "true", node.at_css("[data-slot='checkbox-indicator']")["aria-hidden"]
    assert_empty node.css("[class], [style]")
  end


  test "checkable descriptions are wired to native controls" do
    checkbox = render_node(
      NitroKit::Checkbox.new(
        id: "updates",
        label: "Updates",
        description: "Occasional product news."
      )
    )
    radio = render_node(
      NitroKit::RadioButton.new(
        id: "pro-plan",
        name: "plan",
        label: "Pro",
        description: "For shipping products."
      )
    )

    assert_equal "updates-description", checkbox.at_css("input[type='checkbox']")["aria-describedby"]
    assert_equal "Occasional product news.", checkbox.at_css("[data-slot='checkbox-description']").text
    assert_equal "pro-plan-description", radio.at_css("input[type='radio']")["aria-describedby"]
    assert_equal "For shipping products.", radio.at_css("[data-slot='radio-button-description']").text

    %i[Checkbox RadioButton Switch].each do |component|
      error = assert_raises(ArgumentError) do
        NitroKit.const_get(component).new(id: "solo", description: "Extra", control_aria: { label: "Solo" }).call
      end
      assert_match(/description requires label text or block content/, error.message)
    end
  end

  test "checkable controls mark invalid native inputs" do
    checkbox = render_node(NitroKit::Checkbox.new(label: "Terms", invalid: true))
    radio = render_node(NitroKit::RadioButton.new(label: "Large", invalid: true))
    switch = render_node(NitroKit::Switch.new(label: "Digest", invalid: true))

    assert_equal "true", checkbox.at_css("input[type='checkbox']")["aria-invalid"]
    assert_equal "true", radio.at_css("input[type='radio']")["aria-invalid"]
    assert_equal "true", switch.at_css("input[type='checkbox']")["aria-invalid"]
    assert_nil render_node(NitroKit::Checkbox.new(label: "Terms")).at_css("input[type='checkbox']")["aria-invalid"]
    assert_raises(ArgumentError) { NitroKit::Checkbox.new(label: "Terms", invalid: nil) }
  end

  test "the checkable family shares one size vocabulary" do
    %i[Checkbox RadioButton Switch].each do |component|
      klass = NitroKit.const_get(component)

      assert_equal %i[md lg], klass::SIZES
      assert_equal "lg", render_node(klass.new(label: "Large", size: :lg))["data-size"]
      assert_raises(ArgumentError) { klass.new(label: "Large", size: "lg") }
      assert_raises(ArgumentError) { klass.new(label: "Large", size: :sm) }
    end

    group = render_node(
      NitroKit::CheckboxGroup.new(
        legend: "Features",
        name: "features",
        options: [ [ "Fast", "fast" ] ],
        size: :lg
      )
    )

    assert_equal "lg", group["data-size"]
    assert_equal "lg", group.at_css("[data-nk='checkbox']")["data-size"]
  end

  test "choice groups expose closed layout presentations" do
    checkbox = render_node(
      NitroKit::CheckboxGroup.new(
        legend: "Services",
        name: "services",
        options: [
          {
            label: "Analytics",
            value: "analytics",
            description: "Traffic and conversion reports."
          }
        ],
        presentation: :cards,
        orientation: :horizontal
      )
    )
    radio = render_node(
      NitroKit::RadioButtonGroup.new(
        legend: "Density",
        name: "density",
        options: [ [ "Compact", "compact" ] ],
        presentation: :segmented,
        orientation: :horizontal
      )
    )

    assert_equal "cards", checkbox["data-presentation"]
    assert_equal "horizontal", checkbox["data-orientation"]
    assert_equal "segmented", radio["data-presentation"]
    assert_raises(ArgumentError) do
      NitroKit::CheckboxGroup.new(
        legend: "Bad",
        name: "bad",
        options: [ "One" ],
        presentation: :pills
      )
    end
  end

  test "checkbox supports honest standalone and indeterminate states" do
    standalone = render_node(
      NitroKit::Checkbox.new(
        id: "feature",
        include_hidden: false,
        control_aria: { label: "Enable feature" }
      )
    )
    mixed = render_node(
      NitroKit::Checkbox.new(
        label: "Some",
        id: "some",
        indeterminate: true,
        include_hidden: false
      )
    )

    assert standalone.at_css("input[type='checkbox']")
    assert_equal "true", standalone.at_css("[data-slot='checkbox-indicator']")["aria-hidden"]
    assert_nil standalone.at_css("label")
    assert_nil standalone.at_css("input")["name"]
    assert_equal "indeterminate", mixed["data-state"]
    assert_equal "nk--checkable", mixed["data-controller"]
    assert_equal "true", mixed["data-nk--checkable-indeterminate-value"]
    assert_nil mixed.at_css("input")["aria-checked"]
    assert_equal "control", mixed.at_css("input")["data-nk--checkable-target"]

    ordinary = render_node(NitroKit::Checkbox.new(label: "Some", id: "some", include_hidden: false))

    assert_nil ordinary["data-controller"]
    assert_nil ordinary["data-action"]
    assert_nil ordinary["data-state"]
    assert_nil ordinary.at_css("input")["data-nk--checkable-target"]
    assert_raises(ArgumentError) { NitroKit::Checkbox.new(include_hidden: false).call }
    assert_raises(ArgumentError) { NitroKit::Checkbox.new(checked: 1) }
    assert_raises(ArgumentError) { NitroKit::Checkbox.new(include_hidden: true, unchecked_value: nil) }
  end

  test "checkbox group is a fieldset with one unchecked sentinel and typed choices" do
    node = render_node(
      NitroKit::CheckboxGroup.new(
        legend: "Features",
        description: "Pick any",
        id: "features",
        name: "account[features]",
        value: [ "fast" ],
        options: [
          [ "Fast", "fast" ],
          { label: "Private", value: "private", disabled: true, id: "private-feature" }
        ]
      )
    )
    controls = node.css("input[type='checkbox']")

    assert_equal "fieldset", node.name
    assert_equal "Features", node.at_css("legend").text
    assert_equal "account[features][]", controls.first["name"]
    assert_equal %w[features-0 private-feature], controls.map { |control| control["id"] }
    assert controls.first.key?("checked")
    assert controls.last.key?("disabled")
    assert_equal 1, node.css("input[type='hidden']").count
    assert_empty node.css("[class], [style]")

    assert_raises(ArgumentError) do
      NitroKit::CheckboxGroup.new(legend: "Features", name: nil, options: [ "Fast" ])
    end
    assert_raises(ArgumentError) do
      NitroKit::CheckboxGroup.new(legend: "Features", name: "features", options: [ "Fast", "Fast" ])
    end
    assert_raises(ArgumentError) do
      NitroKit::CheckboxGroup.new(
        legend: "Features",
        id: "features",
        name: "features",
        options: [ [ "Fast", "fast" ], { label: "Private", value: "private", id: "features-0" } ]
      )
    end
    assert_raises(ArgumentError) do
      NitroKit::CheckboxGroup.new(legend: "Features", name: "features", options: [], required: true)
    end
  end

  test "radio button and radio group retain native same-name selection semantics" do
    standalone = render_node(
      NitroKit::RadioButton.new(label: "Large", id: "size-lg", name: "size", value: "lg", checked: true, size: :lg)
    )
    group = render_node(
      NitroKit::RadioButtonGroup.new(
        legend: "Size",
        id: "size",
        name: "account[size]",
        value: "lg",
        required: true,
        options: [ [ "Small", "sm" ], [ "Large", "lg" ] ]
      )
    )

    assert_equal "radio", standalone.at_css("input")["type"]
    assert_equal "lg", standalone["data-size"]
    assert_equal "true", standalone.at_css("[data-slot='radio-button-indicator']")["aria-hidden"]
    assert_equal "fieldset", group.name
    assert_equal %w[account[size] account[size]], group.css("input").map { |input| input["name"] }
    assert_equal "lg", group.at_css("input[checked]")["value"]
    assert group.css("input").all? { |input| input.key?("required") }
    assert_empty group.css("[class], [style]")

    standalone_radio = render_node(
      NitroKit::RadioButton.new(
        id: "standalone-radio",
        control_aria: { label: "Select row" }
      )
    )
    assert_equal "true", standalone_radio.at_css("[data-slot='radio-button-indicator']")["aria-hidden"]
    assert_nil standalone_radio["data-controller"]
    assert_nil standalone_radio["data-state"]
    assert_raises(ArgumentError) { NitroKit::RadioButton.new.call }

    assert_raises(ArgumentError) { NitroKit::RadioButton.new(size: :xl) }
    assert_raises(ArgumentError) { NitroKit::RadioButton.new(size: nil) }
    assert_raises(ArgumentError) do
      NitroKit::RadioButtonGroup.new(legend: "Size", name: "size", options: [ [ "Small", "sm" ] ], size: nil)
    end
    assert_raises(ArgumentError) do
      NitroKit::RadioButtonGroup.new(
        legend: "Size",
        name: "size",
        options: [
          { label: "Small", value: "sm", id: "same" },
          { label: "Large", value: "lg", id: "same" }
        ]
      )
    end
  end

  test "switch is a form-submittable checkbox with an owned switch role" do
    node = render_node(
      NitroKit::Switch.new(
        label: "Weekly digest",
        description: "One summary email",
        id: "digest",
        name: "account[digest]",
        checked: true,
        control_html: { role: "checkbox", title: "Digest" },
        control_aria: { describedby: "account-help" }
      )
    )
    hidden = node.at_css("input[type='hidden']")
    control = node.at_css("input[type='checkbox']")

    assert_equal "switch", node["data-nk"]
    assert_equal "0", hidden["value"]
    assert_equal "switch", control["role"]
    assert_nil control["aria-checked"]
    assert control.key?("checked")
    assert_nil node.at_css("button")
    assert_nil node["data-controller"]
    assert_nil node["data-action"]
    assert_nil node["data-state"]
    assert_equal "account-help digest-description", control["aria-describedby"]
    assert_equal "digest-description", node.at_css("[data-slot='switch-description']")["id"]
    assert node.at_css("label > [data-slot='switch-label-text']")
    # The description is a sibling of the label so it stays out of the
    # control's accessible name and is only announced through describedby.
    assert node.at_css("> [data-slot='switch-description']")
    assert_equal "true", node.at_css("[data-slot='switch-track']")["aria-hidden"]
    assert node.at_css("[data-slot='switch-handle']")
    assert_empty node.css("[class], [style]")

    bare = render_node(NitroKit::Switch.new(control_aria: { label: "Digest" }))

    assert_nil bare.at_css("label")
    assert bare.at_css("[data-slot='switch-track'] > [data-slot='switch-handle']")

    assert_raises(ArgumentError) { NitroKit::Switch.new(size: :sm, label: "Digest") }
    assert_raises(ArgumentError) { NitroKit::Switch.new(size: nil, label: "Digest") }
    assert_raises(ArgumentError) { NitroKit::Switch.new.call }
    assert_raises(ArgumentError) { NitroKit::Switch.new(id: "digest", description: "One summary").call }
    assert_raises(ArgumentError) { NitroKit::Switch.new(label: "Digest", description: "One summary") }
    assert_raises(ArgumentError) { NitroKit::Switch.new(label: "Digest", id: " ", description: "One summary") }
    assert render_node(NitroKit::Switch.new(control_aria: { label: "Digest" })).at_css("input[aria-label='Digest']")
  end

  test "choice groups scope their description and required state to the fieldset" do
    checkbox = render_node(
      NitroKit::CheckboxGroup.new(
        legend: "Features",
        description: "Pick any",
        id: "features",
        name: "features",
        required: true,
        options: [ [ "Fast", "fast" ], [ "Private", "private" ] ]
      )
    )
    radio = render_node(
      NitroKit::RadioButtonGroup.new(
        legend: "Size",
        description: "Pick one",
        id: "size",
        name: "size",
        required: true,
        options: [ [ "Small", "sm" ], [ "Large", "lg" ] ]
      )
    )

    assert_equal "true", checkbox["aria-required"]
    assert_equal "true", radio["aria-required"]
    assert_empty checkbox.css("input[aria-describedby]")
    assert_empty radio.css("input[aria-describedby]")
    assert_equal "features-description", checkbox.at_css("[data-slot='checkbox-group-description']")["id"]
    assert_equal "size-description", radio.at_css("[data-slot='radio-button-group-description']")["id"]
    assert_nil radio["data-required"]
    assert radio.css("input[required]").any?
    assert_empty checkbox.css("input[type='checkbox'][required]")
  end

  test "choice groups require an id-safe name and an explicit selected value" do
    unselected = render_node(
      NitroKit::RadioButtonGroup.new(
        legend: "Size",
        name: "size",
        value: nil,
        options: [ [ "Unspecified", "" ], [ "Large", "lg" ] ]
      )
    )

    assert_empty unselected.css("input[checked]")
    assert_equal "", unselected.at_css("input")["value"]

    [ NitroKit::CheckboxGroup, NitroKit::RadioButtonGroup ].each do |klass|
      error = assert_raises(ArgumentError) do
        klass.new(legend: "Size", name: "!!!", options: [ [ "Large", "lg" ] ])
      end
      assert_match(/cannot derive an id/, error.message)
    end
  end

  test "field group and fieldset expose only qualified structural slots" do
    group = render_node(NitroKit::FieldGroup.new.call { "Fields" })
    fieldset = render_node(
      NitroKit::Fieldset.new(legend: "Profile", description: "Public details").call { "Fields" }
    )

    assert_equal "field-group", group["data-nk"]
    assert_equal "Fields", group.text
    assert_equal "fieldset", fieldset.name
    assert_equal "Profile", fieldset.at_css("[data-slot='fieldset-legend']").text
    assert_equal "Public details", fieldset.at_css("[data-slot='fieldset-description']").text
    assert_equal "Fields", fieldset.at_css("[data-slot='fieldset-fields']").text
    assert_empty fieldset.css("[class], [style]")
    assert_raises(ArgumentError) { NitroKit::FieldGroup.new.call }
    assert_raises(ArgumentError) { NitroKit::Fieldset.new(legend: " ") }
    assert_raises(ArgumentError) { NitroKit::Fieldset.new.call { "Fields" } }
  end

  class DeferredFieldsetProbe < Phlex::HTML
    def view_template
      render NitroKit::Fieldset.new do |fieldset|
        fieldset.description { plain "Public "; strong { "details" } }
        fieldset.legend("Profile")
        plain "Fields"
      end
    end
  end

  test "fieldset accepts compound legend and description declarations" do
    node = Nokogiri::HTML.fragment(DeferredFieldsetProbe.new.call).first_element_child

    assert_equal %w[legend p div], node.element_children.map(&:name)
    assert_equal "Profile", node.at_css("[data-slot='fieldset-legend']").text
    assert_equal "Public details", node.at_css("[data-slot='fieldset-description']").text
    assert_equal "Fields", node.at_css("[data-slot='fieldset-fields']").text
    assert_raises(ArgumentError) do
      NitroKit::Fieldset.new(legend: "Profile").call { |fieldset| fieldset.legend("Again") }
    end
  end

  test "field composes each compound control instead of reimplementing it" do
    select = render_node(
      NitroKit::Field.new(nil, :role, as: :select, options: [ [ "Admin", "admin" ] ], value: "admin")
    )
    checkbox = render_node(NitroKit::Field.new(nil, :terms, as: :checkbox, checked: true))
    radio_group = render_node(
      NitroKit::Field.new(nil, :size, as: :radio_group, value: "lg", options: [ [ "Small", "sm" ], [ "Large", "lg" ] ])
    )
    switch = render_node(NitroKit::Field.new(nil, :digest, as: :switch, label: false))

    assert_equal "select", select.at_css("[data-slot='field-control']")["data-nk"]
    assert_equal "select-control", select.at_css("select")["data-slot"]
    assert_equal "checkbox", checkbox.at_css("[data-slot='field-control']")["data-nk"]
    assert_equal "Terms", checkbox.at_css("[data-slot='checkbox-label-text']").text
    assert_equal "radio-button-group", radio_group.at_css("[data-slot='field-control']")["data-nk"]
    assert_equal "Size", radio_group.at_css("legend").text
    assert_equal "Digest", switch.at_css("input[type='checkbox']")["aria-label"]
    refute_includes switch.text, "Toggle"
    assert_empty select.css("[class], [style]")
    assert_empty checkbox.css("[class], [style]")
    assert_empty radio_group.css("[class], [style]")
    assert_empty switch.css("[class], [style]")
  end

  private

  def render_node(component)
    Nokogiri::HTML.fragment(component.respond_to?(:call) ? component.call : component).first_element_child
  end
end
