# frozen_string_literal: true

module NitroKit
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Fields

    def fieldset(**attrs, &block)
      @template.render(NitroKit::Fieldset.new(**attrs), &block)
    end

    def field(field_name, **attrs)
      label = attrs.fetch(:label, field_name.to_s.humanize)

      errors = object && object.errors.include?(field_name) ? object.errors.full_messages_for(field_name) : nil

      @template.render(NitroKit::Field.new(self, field_name, label:, errors:, **attrs))
    end

    def group(**attrs, &block)
      @template.render(FieldGroup.new(**attrs), &block)
    end

    # Inputs

    %i[
      checkbox
      color_field
      date_field
      datetime_field
      datetime_local_field
      email_field
      file_field
      hidden_field
      month_field
      number_field
      password_field
      phone_field
      radio_button
      range_field
      search_field
      telephone_field
      text_area
      text_field
      time_field
      url_field
      week_field
    ]
      .each do |method|
        define_method(method) do |*args, **attrs, &block|
          @template.send("nk_#{method}", *args, **attrs, &block)
        end
      end

    # Buttons

    def submit(value = "Save changes", **attrs)
      content = value || @template.capture(&block)
      @template.render(NitroKit::Button.new(variant: :primary, type: :submit, **attrs)) { content }
    end

    def button(value = "Save changes", **attrs)
      content = value || @template.capture(&block)
      @template.render(NitroKit::Button.new(**attrs)) { content }
    end
  end
end
