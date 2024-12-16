# frozen_string_literal: true

module NitroKit
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Fields

    def fieldset(options = {}, &block)
      content = @template.capture(&block)
      @template.render(NitroKit::Fieldset.new(options)) { content }
    end

    def field_group(options = {}, &block)
      content = @template.capture(&block)
      @template.render(NitroKit::FieldGroup.new(**options)) { content }
    end

    def field(field_name, **options)
      label = options.fetch(:label, field_name.to_s.humanize)
      errors = object && object.errors.include?(field_name) ? object.errors.full_messages_for(field_name) : nil

      @template.render(NitroKit::Field.new(self, field_name, label:, errors:, **options))
    end

    # Inputs

    def label(field_name, method, content_or_options = nil, options = nil, &block)
    end

    def checkbox(method, options = {}, checked_value = "1", unchecked_value = "0")
      @template.nk_checkbox(@object_name, method, objectify_options(options), label: options[:label])
    end

    alias_method :check_box, :checkbox

    def submit(value = "Save changes", **options)
      content = value || @template.capture(&block)
      @template.render(NitroKit::Button.new(variant: :primary, type: :submit, **options)) { content }
    end

    def button(value = "Save changes", **options)
      content = value || @template.capture(&block)
      @template.render(NitroKit::Button.new(**options)) { content }
    end
  end
end
