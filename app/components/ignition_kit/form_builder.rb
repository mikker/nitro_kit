module IgnitionKit
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Fields

    def fieldset(options = {}, &block)
      content = @template.capture(&block)
      @template.render(IgnitionKit::Fieldset.new(options)) { content }
    end

    def field_group(options = {}, &block)
      content = @template.capture(&block)
      @template.render(IgnitionKit::FieldGroup.new(**options)) { content }
    end

    def field(object_name, **options)
      label = options.fetch(:label, object_name.to_s.humanize)
      errors = object.errors.include?(object_name) ? object.errors.full_messages_for(object_name) : nil

      @template.render(IgnitionKit::Field.new(object_name, label:, errors:, **options))
    end

    # Inputs

    def label(object_name, method, content_or_options = nil, options = nil, &block)
    end

    def checkbox(method, options = {})
      @template.checkbox(@object_name, method, objectify_options(options), label: options[:label])
    end

    alias_method :check_box, :checkbox

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
