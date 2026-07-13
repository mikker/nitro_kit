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

  test "validates textarea constraints passed through the control boundary" do
    field = render_node(
      NitroKit::Field.new(
        nil,
        :bio,
        as: :textarea,
        control_html: { rows: 4, minlength: 20, maxlength: 280, wrap: :hard }
      )
    )
    textarea = field.at_css("textarea")

    assert_equal "4", textarea["rows"]
    assert_equal "20", textarea["minlength"]
    assert_equal "280", textarea["maxlength"]
    assert_equal "hard", textarea["wrap"]

    assert_raises(ArgumentError) do
      NitroKit::Field.new(nil, :bio, as: :textarea, control_html: { rows: 0 }).call
    end
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
    assert_raises(ArgumentError) { NitroKit::Field.new(nil, :query, as: :combobox) }
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
    assert_equal "Save changes", submit.text
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
