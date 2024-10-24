module IgnitionKit
  class FormBuilder < ActionView::Helpers::FormBuilder
    def fieldset(options = {}, &block)
      content = @template.capture(&block)
      @template.render(IgnitionKit::Fieldset.new(options)) { content }
    end

    def field_group(options = {}, &block)
      content = @template.capture(&block)
      @template.render(IgnitionKit::FieldGroup.new(**options)) { content }
    end

    def field(attribute, **options)
      label = options.fetch(:label, attribute.to_s.humanize)
      errors = object.errors.include?(attribute) ? object.errors.full_messages_for(attribute) : nil

      @template.render(IgnitionKit::Field.new(attribute, label:, errors:, **options))
    end

    def submit(value = "Save changes", **options)
      content = value || @template.capture(&block)
      @template.render(IgnitionKit::Button.new(variant: :primary, type: :submit, **options)) { content }
    end

    def button(value = "Save changes", **options)
      content = value || @template.capture(&block)
      @template.render(IgnitionKit::Button.new(**options)) { content }
    end
  end
end
