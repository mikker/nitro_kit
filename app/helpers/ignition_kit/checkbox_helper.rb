module IgnitionKit
  module CheckboxHelper
    # Match the signature of the Rails `check_box` helper
    def ik_checkbox(name, *args)
      if args.length >= 4
        raise ArgumentError, "wrong number of arguments (given #{args.length + 1}, expected 1..4)"
      end

      options = args.extract_options!
      value, checked = args.empty? ? ["1", false] : [*args, false]

      attrs = {
        "type" => "checkbox",
        "name" => name,
        "id" => sanitize_to_id(name),
        "value" => value
      }.update(options.stringify_keys)

      attrs["checked"] = "checked" if checked

      label = attrs.delete("label")

      render(IgnitionKit::Checkbox.new(name, value, label: label, **attrs))
    end
  end
end
