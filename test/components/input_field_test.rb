require "test_helper"

class InputFieldTest < ActiveSupport::TestCase
  class FormProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def initialize(user)
      @user = user
    end

    def view_template
      form_with(model: @user, url: "/users", builder: NitroKit::FormBuilder) do |form|
        form.field(:status, description: "Visible to teammates")
        form.check_box(:active, { include_hidden: true }, "yes", "no")
        form.file_field(:avatar)
        form.submit
      end
    end
  end

  test "renders every input type and validates unknown types" do
    NitroKit::Input::TYPES.each do |type|
      node = render_node(NitroKit::Input.new(type:, name: "value"))

      assert_equal "input", node["data-nk"]
      assert_equal type.to_s, node["type"]
      assert_empty node.css("[class], [style]")
    end

    assert_raises(ArgumentError) { NitroKit::Input.new(type: :made_up) }
    assert_raises(ArgumentError) { NitroKit::Input.new(disabled: "false") }
    assert_raises(ArgumentError) { NitroKit::Input.new(checked: 1) }
  end

  test "normalizes Safari's internal date field alignment on the shared input control" do
    css = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/input.css").read
    date_rule = css[/:where\(\[data-nk="input"\]\[type="date"\]\) \{[^}]+\}/m]
    editor_rule = css[/:where\(\[data-nk="input"\]\[type="date"\]\)::\-webkit-datetime-edit \{[^}]+\}/m]

    refute NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/datepicker.css").exist?
    assert date_rule, "input.css must own the date alignment rule"
    assert_includes date_rule, "block-size: var(--nk-control-height-md)"
    assert_includes date_rule, "padding-block: 0"
    assert_includes date_rule, "line-height: calc("
    assert editor_rule, "input.css must normalize Safari's native date editor"
    assert_includes editor_rule, "line-height: normal"
  end

  test "normalizes datetime-local values and never gives file inputs a value" do
    datetime = render_node(
      NitroKit::Field.new(nil, :starts_at, as: :datetime_local, value: Time.utc(2026, 7, 13, 10, 30))
    )
    file = render_node(NitroKit::Field.new(nil, :attachment, as: :file, value: "secret.txt"))

    assert_equal "datetime-local", datetime.at_css("input")["type"]
    assert_equal "2026-07-13T10:30:00", datetime.at_css("input")["value"]
    assert_nil file.at_css("input")["value"]

    assert_raises(ArgumentError) do
      NitroKit::Input.new(type: :file, value: "ignored", html: { value: "bypass" })
    end
    assert_raises(ArgumentError) do
      NitroKit::Field.new(nil, :attachment, as: :file, control_html: { value: "bypass" }).call
    end
  end

  test "renders nested input ownership and invalid semantics" do
    node = render_node(
      NitroKit::Field.new(
        nil,
        :email,
        id: "account-email",
        label: "Email",
        description: "Work address",
        errors: [ "Email is invalid" ],
        value: "not-an-email"
      )
    )
    control = node.at_css("[data-slot='field-control']")

    assert_equal "field", node["data-nk"]
    assert_equal "invalid", node["data-state"]
    assert_equal "input", control["data-nk"]
    assert_equal "account-email-description account-email-errors", control["aria-describedby"]
    assert_equal "true", control["aria-invalid"]
    assert_equal "Email is invalid", node.at_css("[data-slot='field-error']").text
    assert_empty node.css("[class], [style]")
  end

  test "suppresses false labels and renders true blank options as empty" do
    unlabeled = render_node(NitroKit::Field.new(nil, :query, label: false, value: "Nitro"))
    select = render_node(
      NitroKit::Field.new(nil, :role, as: :select, include_blank: true, options: [ [ "Admin", "admin" ] ])
    )

    assert_nil unlabeled.at_css("[data-slot='field-label']")
    assert_equal "", select.at_css("option").text
    assert_equal "", select.at_css("option")["value"]
  end

  test "validates textarea constraints passed as field keywords" do
    field = render_node(
      NitroKit::Field.new(nil, :bio, as: :textarea, rows: 4, minlength: 20, maxlength: 280, wrap: :hard)
    )
    textarea = field.at_css("textarea")

    assert_equal "4", textarea["rows"]
    assert_equal "20", textarea["minlength"]
    assert_equal "280", textarea["maxlength"]
    assert_equal "hard", textarea["wrap"]

    assert_raises(ArgumentError) { NitroKit::Field.new(nil, :bio, as: :textarea, rows: 0).call }
    assert_raises(ArgumentError) { NitroKit::Field.new(nil, :bio, as: :string, rows: 4) }
    owned = assert_raises(ArgumentError) do
      NitroKit::Field.new(nil, :bio, as: :textarea, control_html: { rows: 4 }).call
    end
    assert_equal "rows is owned by Textarea; pass rows: as a keyword", owned.message
  end

  test "input owns its native attributes and rejects them through html" do
    node = render_node(NitroKit::Input.new(id: "bio", minlength: 2, maxlength: 40))

    assert_equal "2", node["minlength"]
    assert_equal "40", node["maxlength"]
    assert_raises(ArgumentError) { NitroKit::Input.new(minlength: 4, maxlength: 2) }
    assert_raises(ArgumentError) { NitroKit::Input.new(maxlength: -1) }

    owned = assert_raises(ArgumentError) { NitroKit::Input.new(html: { maxlength: 40 }) }
    assert_equal "maxlength is owned by Input; pass maxlength: as a keyword", owned.message

    file = assert_raises(ArgumentError) { NitroKit::Input.new(type: :file, value: "secret.txt") }
    assert_equal "file inputs never carry a value; omit value:", file.message
  end

  test "field errors announce through an alert region" do
    node = render_node(NitroKit::Field.new(nil, :email, errors: [ "Email is invalid" ]))
    errors = node.at_css("[data-slot='field-error']")

    assert_equal "alert", errors["role"]
    assert_nil errors["aria-live"]
    assert_equal "email-errors", errors["id"]
  end

  test "field identifies its control type without colliding with application data" do
    node = render_node(NitroKit::Field.new(nil, :bio, as: :textarea, data: { type: "biography" }))

    assert_equal "textarea", node["data-field-type"]
    assert_equal "biography", node["data-type"]
  end

  test "field refuses an unnamed radio group and names its error after the as keyword" do
    assert_raises(ArgumentError) do
      NitroKit::Field.new(nil, :size, as: :radio_group, label: false, options: [ [ "Small", "sm" ] ])
    end

    unknown = assert_raises(ArgumentError) { NitroKit::Field.new(nil, :query, as: :calendar) }
    assert_match(/Unknown as/, unknown.message)
  end

  test "combobox fields wire the field label description and invalid state to the input" do
    node = render_node(
      NitroKit::Field.new(
        nil,
        :country,
        as: :combobox,
        label: "Country",
        description: "Used for tax rules",
        errors: [ "Country is not included in the list" ],
        options: [ [ "Denmark", "dk" ], [ "Sweden", "se" ] ],
        value: "dk",
        placeholder: "Search countries",
        required: true
      )
    )
    label = node.at_css("[data-slot='field-label']")
    control = node.at_css("[data-slot='field-control']")
    input = control.at_css("[data-slot='combobox-input']")
    select = control.at_css("[data-slot='combobox-native'] select")

    assert_equal "combobox", node["data-field-type"]
    assert_equal "combobox", control["data-nk"]
    assert_equal "country-label", label["id"]
    assert_equal "country-input", label["for"]
    assert_nil control.at_css("[data-slot='combobox-label']")
    assert_equal "country-label", input["aria-labelledby"]
    assert_equal "country-description country-errors", input["aria-describedby"]
    assert_equal "true", input["aria-invalid"]
    assert_equal "Search countries", input["placeholder"]
    assert_equal "Denmark", input["value"]
    assert_equal "country", select["name"]
    assert_equal "dk", select.at_css("option[selected]")["value"]
    assert_equal 1, node.css("[name='country']").size
  end

  test "an unlabelled combobox field names the input from the field name" do
    node = render_node(
      NitroKit::Field.new(nil, :country, as: :combobox, label: false, options: [ [ "Denmark", "dk" ] ])
    )

    assert_nil node.at_css("[data-slot='field-label']")
    assert_equal "Country", node.at_css("[data-slot='combobox-input']")["aria-label"]
  end

  test "rich text fields carry the field validation and description wiring" do
    node = render_node(
      NitroKit::Field.new(
        nil,
        :notes,
        as: :rich_text,
        description: "Add useful context",
        errors: [ "Notes is required" ],
        rich_text_content: "<lexxy-editor></lexxy-editor>".html_safe,
        control_data: { tracking_id: "notes" }
      )
    )
    control = node.at_css("[data-slot='field-control']")

    assert_equal "rich-text-area", control["data-nk"]
    assert_equal "true", control["aria-invalid"]
    assert_equal "notes-description notes-errors", control["aria-describedby"]
    assert_equal "notes", control["data-tracking-id"]
  end

  test "derives direct field identity and validates its closed semantics" do
    node = render_node(
      NitroKit::Field.new(nil, :billing_email, description: "Receipts", required: true, disabled: true)
    )
    control = node.at_css("input")

    assert_equal "true", node["data-required"]
    assert_equal "true", node["data-disabled"]
    assert_equal "billing_email", control["id"]
    assert_equal "billing_email", control["name"]
    assert_equal "billing_email", node.at_css("label")["for"]
    assert_equal "billing_email-description", control["aria-describedby"]
    assert_raises(ArgumentError) { NitroKit::Field.new(nil, :query, as: :calendar) }
    assert_raises(ArgumentError) { NitroKit::Field.new(nil, :query, required: "false") }
    assert_raises(ArgumentError) { NitroKit::Field.new(nil, :query, include_hidden: nil) }
  end

  test "keeps Rails form naming IDs values and builder submit semantics" do
    user = User.new(status: "active")
    html = ApplicationController.render(FormProbe.new(user))
    form = Nokogiri::HTML(html).at_css("form")
    control = form.at_css("[data-slot='field-control']")
    submit = form.at_css("button[type='submit']")
    checkbox = form.at_css("input[type='checkbox']")
    hidden = form.at_css("input[type='hidden'][name='user[active]']")
    file = form.at_css("input[type='file']")

    assert_equal "multipart/form-data", form["enctype"]
    assert_equal "user_status", control["id"]
    assert_equal "user[status]", control["name"]
    assert_equal "active", control["value"]
    assert_equal "Status", form.at_css("[data-slot='field-label']").text
    assert_equal I18n.t("nitro_kit.form.submit"), submit.text
    assert_equal "primary", submit["data-variant"]
    assert_equal "yes", checkbox["value"]
    assert_equal "no", hidden["value"]
    assert_nil file["value"]
  end

  private

  def render_node(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
