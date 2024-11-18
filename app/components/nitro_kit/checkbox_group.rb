module NitroKit
  class CheckboxGroup < Component
    def initialize(options = nil, **attrs)
      super(**attrs)

      @options = options
    end

    attr_reader :options

    def view_template
      div(class: "flex items-start flex-col gap-2") do
        block_given? ? yield : options.map { |o| item(*o) }
      end
    end

    def title(text = nil, **attrs)
      render(Label.new(**attrs)) { text || yield }
    end

    def item(text = nil, value = nil, **attrs)
      value ||= attrs.fetch(:value, text)

      render(
        Checkbox.new(
          value:,
          label: text,
          **attrs
        )
      )
    end
  end
end
