# frozen_string_literal: true

module NitroKit
  module CheckboxHelper
    # Make API compatible with Rails' checkbox but allow empty arguments
    def nk_checkbox(
      compat_object_name = nil,
      compat_method = nil,
      compat_options = {},
      compat_checked_value = "1",
      compat_unchecked_value = "0",
      label: nil,
      **attrs
    )
      name = field_name(compat_object_name, compat_method)
      checked = compat_options["checked"] || attrs[:checked]

      # TODO: multiple, unchecked hidden field

      render(Checkbox.new(name:, label:, value: compat_checked_value, checked:, **attrs))
    end

    def nk_checkbox_tag(name, *args)
      if args.length >= 4
        raise ArgumentError, "wrong number of arguments (given #{args.length + 1}, expected 1..4)"
      end

      options = args.extract_options!
      value, checked = args.empty? ? ["1", false] : [*args, false]
      attrs = {
        type: "checkbox",
        name: name,
        id: sanitize_to_id(name),
        value: value
      }.update(
        options.symbolize_keys
      )

      attrs[:checked] = "checked" if checked

      render(Checkbox.new(name:, **attrs))
    end

    alias :nk_check_box_tag :nk_checkbox_tag

    def nk_checkbox_group(**attrs, &block)
      render(CheckboxGroup.new(**attrs), &block)
    end
  end
end
