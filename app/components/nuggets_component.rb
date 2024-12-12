class NuggetsComponent < Phlex::HTML
  class NuggetBadge < NitroKit::Badge
    def initialize(component)
      super(name(component), variant: component, size: :sm)
    end

    private

    def variant_class
      case variant
      when :component
        "bg-violet-100 border-violet-300 border text-violet-700 dark:bg-violet-950 dark:border-violet-800 dark:text-violet-400"
      when :js
        "bg-yellow-100 border-yellow-300 border text-yellow-700 dark:bg-yellow-950 dark:border-yellow-800 dark:text-yellow-400"
      end
    end

    def name(component)
      case component
      when :component
        "Ruby"
      when :js
        "Stimulus"
      end
    end
  end

  def initialize(kinds)
    @kinds = kinds
  end

  attr_reader :kinds

  def view_template
    div(class: "flex gap-2") do
      kinds.each do |kind|
        render(NitroKit::Tooltip.new(content: tooltip(kind))) do
          render(NuggetBadge.new(kind))
        end
      end
    end
  end

  private

  def tooltip(kind)
    case kind
    when :component
      "Includes a Ruby component and corresponding Rails helper"
    when :js
      "Includes a Stimulus controller"
    end
  end
end
