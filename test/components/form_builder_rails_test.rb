require "test_helper"

class FormBuilderRailsTest < ActiveSupport::TestCase
  class SelectBlockProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def initialize(registration)
      @registration = registration
    end

    def view_template
      form_with(model: @registration, url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.select(:role, nil, {}, data: { tracking_id: "role" }) do
          option(value: "developer") { "Developer" }
          option(value: "designer", selected: @registration.role == "designer") { "Designer" }
        end
      end
    end
  end

  class MultipleSelectProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      form_with(model: Registration.new, url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.select(
          :role,
          [ [ "Developer", "developer" ], [ "Designer", "designer" ] ],
          { selected: %w[developer designer] },
          { multiple: true }
        )
      end
    end
  end

  class SafeOptionsProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      option_tags = <<~HTML.html_safe
        <option value="developer">Developer</option>
        <option value="designer" selected>Designer</option>
      HTML

      form_with(model: Registration.new(role: "designer"), url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.select(:role, option_tags)
      end
    end
  end

  class NativeHelpersProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      registration = Registration.new(source: "probe", terms: true)

      form_with(model: registration, url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.hidden_field(:source)
        form.check_box(:terms, { include_hidden: true }, "yes", "no")
        form.file_field(:attachment, accept: "text/plain")
        form.text_field(
          :email,
          maxlength: 40,
          data: { tracking_id: "email" },
          aria: { describedby: "email-help" }
        )
      end
    end
  end

  class StructuralProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      form_with(model: Registration.new, url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.fieldset(legend: "Profile", description: "Public details") do
          form.group do
            form.field(:email, as: :email)
            form.field(:role, as: :radio_group, options: [ [ "Developer", "developer" ], [ "Designer", "designer" ] ])
          end
        end
      end
    end
  end

  class RichTextProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    class RichTextFormBuilder < NitroKit::FormBuilder
      def rich_text_area(field_name, options = {})
        @template.tag.lexxy_editor(
          @template.tag.input(type: "hidden", name: self.field_name(field_name), id: options[:id]),
          input: options[:id]
        )
      end
    end

    def view_template
      registration = Registration.new
      registration.define_singleton_method(:notes) { "<p>Useful context</p>" }

      form_with(model: registration, url: "/registration", builder: RichTextFormBuilder) do |form|
        form.field(:notes, as: :rich_text, description: "Add useful context")
      end
    end
  end

  class BoundaryProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      form_with(model: Registration.new, url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.field(
          :email,
          as: :email,
          data: { tracking_id: "email" },
          aria: { keyshortcuts: "e" },
          wrapper_data: { section: "identity" },
          wrapper_html: { id: "email-wrapper" }
        )
        form.text_field(:role, data: { tracking_id: "role" })
        form.button("Continue")
        form.submit("Register")
      end
    end
  end

  class ComboboxProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      registration = Registration.new(role: "designer")
      registration.errors.add(:role, "is not available")

      form_with(model: registration, url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.field(
          :role,
          as: :combobox,
          description: "Determines default permissions",
          options: [
            { label: "Developer", value: "developer", description: "Ships application code" },
            [ "Designer", "designer" ]
          ],
          required: true
        )
      end
    end
  end

  test "combobox fields keep Rails naming inside ordinary Field anatomy" do
    form = render_form(ComboboxProbe.new)
    field = form.at_css("[data-nk='field'][data-field-type='combobox']")
    label = field.at_css("[data-slot='field-label']")
    combobox = field.at_css("[data-slot='field-control'][data-nk='combobox']")
    input = combobox.at_css("[data-slot='combobox-input']")
    select = combobox.at_css("[data-slot='combobox-native'] select")

    assert_equal "invalid", field["data-state"]
    assert_equal "Role", label.text
    assert_equal "registration_role-input", label["for"]
    assert_equal "registration_role-label", input["aria-labelledby"]
    assert_equal "registration_role-description registration_role-errors", input["aria-describedby"]
    assert_equal "true", input["aria-invalid"]
    assert_equal "Designer", input["value"]
    assert_equal "registration[role]", select["name"]
    assert_equal "registration_role-value", select["id"]
    assert_equal "designer", select.at_css("option[selected]")["value"]
    assert_equal 1, form.css("[name='registration[role]']").size
    assert_equal(
      "Ships application code",
      combobox.at_css("[data-slot='combobox-option'][data-value='developer'] [data-slot='combobox-option-description']").text
    )
  end

  test "builder data and aria always decorate the control" do
    form = render_form(BoundaryProbe.new)
    wrapper = form.at_css("#email-wrapper")
    email = wrapper.at_css("input[type='email']")
    role = form.at_css("input[type='text']")

    assert_equal "identity", wrapper["data-section"]
    assert_nil wrapper["data-tracking-id"]
    assert_equal "email", email["data-tracking-id"]
    assert_equal "e", email["aria-keyshortcuts"]
    assert_equal "role", role["data-tracking-id"]
  end

  test "builder buttons and submits keep Rails submission semantics" do
    form = render_form(BoundaryProbe.new)
    buttons = form.css("[data-nk='button']")

    assert_equal %w[submit submit], buttons.map { |button| button["type"] }
    assert_equal "commit", buttons.last["name"]
    assert_equal "Register", buttons.last["value"]
  end

  test "builder rejects ambiguous and unsupported form helpers" do
    builder = NitroKit::FormBuilder.new(:registration, Registration.new, ApplicationController.new.view_context, {})

    duplicate = assert_raises(ArgumentError) do
      builder.field(:email, data: { tracking_id: "one" }, control_data: { tracking_id: "two" })
    end
    assert_match(/tracking_id was given through both data: and control_data:/, duplicate.message)

    unknown = assert_raises(ArgumentError) { builder.field(:email, as: :combo_box) }
    assert_match(/Unknown as: :combo_box/, unknown.message)

    unsupported = assert_raises(ArgumentError) { builder.collection_select(:role, [], :id, :name) }
    assert_match(/does not implement collection_select/, unsupported.message)
    assert_raises(ArgumentError) { builder.label(:role) }
    assert_raises(ArgumentError) { builder.date_select(:created_at) }
    assert_raises(ArgumentError) { builder.time_zone_select(:zone) }
    assert_raises(ArgumentError) { builder.collection_check_boxes(:roles, [], :id, :name) }
    assert_raises(ArgumentError) { builder.collection_radio_buttons(:role, [], :id, :name) }
    assert_raises(ArgumentError) { builder.grouped_collection_select(:role, [], :a, :b, :c, :d) }
  end

  class TranslatedRegistration < Registration
    def self.human_attribute_name(attribute, options = {})
      attribute.to_s == "email" ? "Email address" : super
    end
  end

  class StrictRegistration < Registration
    def self.human_attribute_name(attribute, options = {})
      raise I18n::MissingTranslationData.new(I18n.locale, "activemodel.attributes.strict_registration.#{attribute}", options) if attribute.to_s == "virtual_setting"

      super
    end
  end

  class CustomFieldBlockProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      form_with(model: StrictRegistration.new, url: "/registration", builder: NitroKit::FormBuilder) do |form|
        form.field(:virtual_setting) do |field|
          field.label("Virtual setting")
          field.control
        end
      end
    end
  end

  class TranslatedLabelProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      form_with(
        model: TranslatedRegistration.new,
        scope: :registration,
        url: "/registration",
        builder: NitroKit::FormBuilder
      ) do |form|
        form.field(:email, as: :email)
        form.field(:role, as: :radio_group, options: [ [ "Developer", "developer" ] ])
      end
    end
  end

  test "custom field blocks do not eagerly resolve an unused implicit label" do
    form = render_form(CustomFieldBlockProbe.new)

    assert_equal "Virtual setting", form.at_css("[data-slot='field-label']").text
    assert form.at_css("input[type='text']")
  end

  test "builder labels come from Rails human attribute names" do
    form = render_form(TranslatedLabelProbe.new)

    assert_equal "Email address", form.at_css("[data-slot='field-label']").text
    assert_equal "Role", form.at_css("legend").text
  end

  test "captures select blocks inside the native select control" do
    form = render_form(SelectBlockProbe.new(Registration.new(role: "designer")))
    select = form.at_css("[data-nk='select'][data-slot='field-control'] select")

    assert_equal 2, select.css("option").count
    assert_equal "designer", select.at_css("option[selected]")["value"]
    assert_equal "role", select["data-tracking-id"]
    assert_empty form.css("[data-nk='field'] > option")
  end

  test "preserves explicit selected arrays and multiple select semantics" do
    select = render_form(MultipleSelectProbe.new).at_css("select")

    assert select.key?("multiple")
    assert_equal "registration[role][]", select["name"]
    assert_equal %w[developer designer], select.css("option[selected]").map { |option| option["value"] }
  end

  test "preserves trusted Rails-generated option markup" do
    select = render_form(SafeOptionsProbe.new).at_css("select")

    assert_equal 2, select.css("option").count
    assert_equal "designer", select.at_css("option[selected]")["value"]
  end

  test "keeps native helper behavior at the control boundary" do
    form = render_form(NativeHelpersProbe.new)
    hidden = form.at_css("input[type='hidden'][name='registration[source]']")
    checkbox = form.at_css("input[type='checkbox']")
    file = form.at_css("input[type='file']")
    text = form.at_css("input[type='text']")

    assert_equal "multipart/form-data", form["enctype"]
    assert_equal "probe", hidden["value"]
    assert_nil hidden.ancestors.find { |node| node["data-nk"] == "field" }
    assert_equal "yes", checkbox["value"]
    assert checkbox.key?("checked")
    assert_equal "no", form.at_css("input[type='hidden'][name='registration[terms]']")["value"]
    assert_equal "text/plain", file["accept"]
    assert_nil file["value"]
    assert_equal "40", text["maxlength"]
    assert_equal "email", text["data-tracking-id"]
    assert_equal "email-help", text["aria-describedby"]
    assert_empty form.css("[class], [style]")
  end

  test "composes builder fieldsets groups and native radio fieldsets" do
    form = render_form(StructuralProbe.new)
    fieldset = form.at_css("fieldset[data-nk='fieldset']")
    group = fieldset.at_css("[data-nk='field-group']")
    radio_group = group.at_css("fieldset[data-nk='radio-button-group']")

    assert_equal "Profile", fieldset.at_css("legend[data-slot='fieldset-legend']").text
    assert_equal "Public details", fieldset.at_css("[data-slot='fieldset-description']").text
    assert_equal 2, group.xpath("./*[@data-nk='field']").count
    assert_equal "Role", radio_group.at_css("legend").text
    assert_equal %w[registration[role] registration[role]], radio_group.css("input[type='radio']").map { |input| input["name"] }
    assert_empty form.css("[class], [style]")
  end

  test "wraps the installed Action Text editor in the Nitro field contract" do
    form = render_form(RichTextProbe.new)
    field = form.at_css("[data-nk='field']")

    assert_equal "rich-text", field["data-field-type"]
    assert_equal "Notes", field.at_css("[data-slot='field-label']").text
    assert_equal "Add useful context", field.at_css("[data-slot='field-description']").text
    assert form.at_css("[data-nk='rich-text-area']")
    assert form.at_css("input[type='hidden'][name='registration[notes]']")
  end

  private

  def render_form(component)
    html = ApplicationController.render(component, layout: false)
    Nokogiri::HTML.fragment(html).at_css("form")
  end
end
