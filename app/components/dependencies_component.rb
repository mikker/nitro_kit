class DependenciesComponent < Phlex::HTML
  def initialize(component)
    @modules = component.modules
    @gems = component.gems
  end

  attr_reader :modules, :gems

  def view_template
    ul(class: "list-disc list-inside pl-2 text-sm leading-relaxed") do
      modules.each do |path|
        li do
          code { path }
        end
      end

      gems.each do |path|
        li do
          code { path }
        end
      end
    end
  end
end
