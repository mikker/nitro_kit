module NitroKit
  module CheckboxHelper
    # Match the signature of the Rails `check_box` helper
    def nk_checkbox(name, *args)
      if args.length >= 4
        raise ArgumentError, "wrong number of arguments (given #{args.length + 1}, expected 1..4)"
      end

      options = args.extract_options!
      value, checked = args.empty? ? ["1", false] : [*args, false]

      attrs = {
        :type => "checkbox",
        :name => name,
        :id => sanitize_to_id(name),
        :value => value
      }.update(options.symbolize_keys)

      attrs[:checked] = "checked" if checked

      render(NitroKit::Checkbox.new(name, value:, **attrs))
    end
  end
end
