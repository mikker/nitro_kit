module NitroKit
  class RadioGroup < Component
    include ActionView::Helpers::FormTagHelper

    def initialize(options = nil, name: nil, value: nil, **attrs)
      super(**attrs)

      @options = options

      @name = name
      @group_value = value
    end

    attr_reader :name, :group_value, :options

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
        RadioButton.new(
          name:,
          value:,
          label: text,
          checked: group_value.presence == value,
          **attrs
        )
      )
    end
  end
end
