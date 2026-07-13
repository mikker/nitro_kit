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
    assert_raises(ArgumentError) do
      NitroKit::Textarea.new(html: { rows: 0, wrap: "sideways", maxlength: -1 })
    end
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
    assert_raises(ArgumentError) { NitroKit::Choice.coerce([ "Admin", "admin", "false" ]) }
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
    assert_equal "select-icon", node.at_css("svg")["data-slot"]
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
    assert_equal "checkbox-indicator", node.at_css("[data-slot='checkbox-indicator']")["data-slot"]
    assert_empty node.css("[class], [style]")
  end

  test "checkbox supports honest standalone and indeterminate states" do
    standalone = render_node(NitroKit::Checkbox.new(id: "feature", include_hidden: false))
    mixed = render_node(NitroKit::Checkbox.new(label: "Some", indeterminate: true, include_hidden: false))

    assert standalone.at_css("input[type='checkbox']")
    assert standalone.at_css("[data-slot='checkbox-indicator']")
    assert_nil standalone.at_css("label")
    assert_nil standalone.at_css("input")["name"]
    assert_equal "indeterminate", mixed["data-state"]
    assert_equal "mixed", mixed.at_css("input")["aria-checked"]
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
    assert_equal "fieldset", group.name
    assert_equal %w[account[size] account[size]], group.css("input").map { |input| input["name"] }
    assert_equal "lg", group.at_css("input[checked]")["value"]
    assert group.css("input").all? { |input| input.key?("required") }
    assert_empty group.css("[class], [style]")

    assert_raises(ArgumentError) { NitroKit::RadioButton.new(size: :xl) }
    assert_raises(ArgumentError) { NitroKit::RadioButton.new(size: nil) }
    assert_raises(ArgumentError) do
      NitroKit::RadioButtonGroup.new(legend: "Size", name: "size", options: [ [ "Small", "sm" ] ], size: nil)
    end
    assert_raises(ArgumentError) do
      NitroKit::RadioButtonGroup.new(legend: "Size", name: "size", options: [ [ "Small", "sm", false, "same" ], [ "Large", "lg", false, "same" ] ])
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
        control_html: { role: "checkbox", title: "Digest" }
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
    assert_nil node.at_css("[data-controller]")
    assert node.at_css("[data-slot='switch-track']")
    assert node.at_css("[data-slot='switch-handle']")
    assert_empty node.css("[class], [style]")

    assert_raises(ArgumentError) { NitroKit::Switch.new(size: :lg, label: "Digest") }
    assert_raises(ArgumentError) { NitroKit::Switch.new(size: nil, label: "Digest") }
    assert_raises(ArgumentError) { NitroKit::Switch.new.call }
    assert render_node(NitroKit::Switch.new(control_aria: { label: "Digest" })).at_css("input[aria-label='Digest']")
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
