class ExampleComponent < Phlex::HTML
  class ExampleTabs < NitroKit::Tabs
    private

    def base_class
      "border rounded-xl overflow-hidden"
    end

    def tabs_class
      "border-b-2 bg-muted"
    end

    def tab_class
      "px-4 font-semibold text-xs text-muted-foreground aria-selected:text-foreground py-2 border-b-2 aria-selected:border-primary -mb-[2px]"
    end

    def panel_class
      "aria-[hidden=true]:hidden bg-background"
    end
  end

  def initialize(path, language: "erb", copy_button: true)
    @path = path
    @contents = File.read(Rails.root.join("app/views/examples/_#{path}.html.erb"))
    @language = language
    @copy_button = copy_button
  end

  attr_reader :path, :contents, :language, :copy_button

  def view_template
    render(ExampleTabs.new(default: :preview)) do |t|
      t.tabs do
        t.tab(:preview, "Preview")
        t.tab(:code, "Code")
      end

      t.panel(:preview) do
        div(class: "flex justify-center items-center px-4 py-12 min-h-[120px]") do
          yield
        end
      end

      t.panel(:code) do
        render(CodeComponent.new(contents, language:))
      end
    end
  end
end
