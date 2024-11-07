module NitroKit
  class RadioGroup < Component
    include ActionView::Helpers::FormTagHelper

    def initialize(name, value: nil, **options)
      super(**options)
      @name = name
      @group_value = value
    end

    attr_reader :name, :id, :group_value

    def view_template
      div(class: "flex items-start flex-col gap-2") do
        yield
      end
    end

    def title(text = nil, **options)
      render(Label.new(**options)) { text || yield }
    end

    def item(value, text = nil, **options)
      render(
        RadioButton.new(
          name,
          id:,
          value:,
          checked: group_value.presence == value,
          **options
        )
      ) { text || yield }
    end
  end
end
