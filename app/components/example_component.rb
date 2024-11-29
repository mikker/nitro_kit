class ExampleComponent < Phlex::HTML
  class ExampleTabs < NitroKit::Tabs
    private

    def base_class
      "border rounded-md overflow-hidden"
    end

    def tabs_class
      "border-b-2"
    end

    def tab_class
      "px-4 font-semibold text-sm text-muted-foreground aria-selected:text-foreground py-2 border-b-2 aria-selected:border-primary -mb-[2px]"
    end

    def panel_class
      "aria-[hidden=true]:hidden bg-muted"
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
        div(class: "flex justify-center items-center p-4") do
          yield
        end
      end

      t.panel(:code, class: "relative", data: {controller: "copy-to-clipboard"}) do
        copy_button_element if copy_button
        code_example(contents, data: {copy_to_clipboard_target: "source"})
      end
    end
  end

  private

  def code_example(contents, **attrs)
    lexer = Rouge::Lexer.find(language)
    formatter = Rouge::Formatters::HTML.new

    pre(
      class: "text-sm highlight py-3 px-4 font-mono overflow-scroll",
      **attrs
    ) do
      code do
        formatter.format(lexer.lex(contents)).html_safe
      end
    end
  end

  def copy_button_element
    div(class: "absolute top-2 right-2") do
      render(
        NitroKit::Button
          .new(
            icon: :copy,
            size: :sm,
            data: {copy_to_clipboard_target: "button", action: "copy-to-clipboard#copy"}
          )
      )
      render(
        NitroKit::Button
          .new(
            icon: :check,
            size: :sm,
            data: {copy_to_clipboard_target: "successMessage"},
            class: "hidden"
          )
      )
    end
  end
end
