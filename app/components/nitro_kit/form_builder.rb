# frozen_string_literal: true

module NitroKit
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Fields

    def fieldset(**attrs, &block)
      @template.render(NitroKit::Fieldset.new(**attrs), &block)
    end

    def field(field_name, label: nil, errors: nil, **attrs, &block)
      if label.nil?
        label = attrs.fetch(:label, field_name.to_s.humanize)
      end

      if errors.nil?
        errors = object && object.respond_to?(:errors) && object.errors.include?(field_name) ? object
          .errors
          .full_messages_for(field_name) : nil
      end

      @template.render(NitroKit::Field.new(self, field_name, label:, errors:, **attrs), &block)
    end

    def group(**attrs, &block)
      @template.render(FieldGroup.new(**attrs), &block)
    end

    # Input types

    %i[
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
          type = method.to_s.gsub(/_field$/, "")
          field(*args, **attrs, type:, label: false, &block)
        end
      end

    def checkbox(method, checked_value = "1", unchecked_value = "0", *args, include_hidden: true, **attrs)
      if include_hidden
        @template.concat(hidden_field(method, value: unchecked_value))
      end

      field(method, *args, as: :checkbox, label: false, value: checked_value, **attrs)
    end

    # Buttons

    def submit(value = nil, **attrs, &block)
      if value
        content = value
      elsif block_given?
        content = @template.capture(&block)
      else
        content = I18n.t("save_changes")
      end

      @template.render(NitroKit::Button.new(variant: :primary, type: :submit, **attrs)) { content }
    end

    def button(value = "Save changes", **attrs)
      content = value || @template.capture(&block)
      @template.render(NitroKit::Button.new(**attrs)) { content }
    end
  end
end
