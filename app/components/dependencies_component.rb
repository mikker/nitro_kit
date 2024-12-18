class DependenciesComponent < Phlex::HTML
  def initialize(component)
    @modules = component.all_modules
    @gems = component.all_gems
  end

  attr_reader :modules, :gems

  def view_template
    ul(class: "list-disc list-inside pl-2 text-sm leading-relaxed") do
      gems.each do |name|
        item(name, kind: "Ruby")
      end

      modules.each do |name|
        item(name, kind: "JavaScript")
      end
    end
  end

  private

  def item(name, kind:)
    web, gh = outbounds(name)

    li(class: "flex gap-2 mb-1") do
      render(NitroKit::Badge.new(kind, size: :sm))
      code { name }
      render(NitroKit::Button.new("Web", href: web, size: :xs, icon: :globe, target: :_blank))
      render(NitroKit::Button.new("GitHub", href: gh, size: :xs, icon: :github, target: :_blank))
    end
  end

  def outbounds(name)
    case name
    when "@floating-ui/core", "@floating-ui/dom"
      ["https://floating-ui.com/", "https://github.com/floating-ui/floating-ui"]
    when "@github/combobox-nav"
      ["https://floating-ui.com/", "https://github.com/floating-ui/floating-ui"]
    when "lucide-rails"
      ["https://lucide.dev/", "https://github.com/heyvito/lucide-rails"]
    else raise ArgumentError, "Unknown dependency `#{name}'"
    end
  end
end
