module NitroKit
  module RadioButtonHelper
    def ik_radio_button(name, value, *args)
      if args.length >= 3
        raise ArgumentError, "wrong number of arguments (given #{args.length + 2}, expected 2..4)"
      end

      options = args.extract_options!
      checked = args.empty? ? false : args.first

      options[:checked] = "checked" if checked

      render(RadioButton.new(name, value:, name:, value:, **options))
    end

    def ik_radio_group(name, **options, &block)
      render(RadioGroup.new(name, **options, &block))
    end
  end
end
