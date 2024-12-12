class CodeComponent < Phlex::HTML
  def initialize(content, language:, copy_button: true, **attrs)
    @content = content
    @copy_button = copy_button
    @attrs = attrs

    @lexer = Rouge::Lexer.find(language)
    @formatter = Rouge::Formatters::HTML.new
  end

  attr_reader :content, :language, :copy_button, :attrs

  def view_template
    div(class: "relative p-2", data: {controller: "copy-to-clipboard"}) do
      copy_button_element if copy_button

      pre(
        class: "text-sm highlight py-3 px-4 font-mono overflow-scroll",
        data: {copy_to_clipboard_target: "source"},
        **attrs
      ) do
        code do
          @formatter.format(@lexer.lex(content)).html_safe
        end
      end
    end
  end

  private

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
