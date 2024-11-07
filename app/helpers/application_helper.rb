module ApplicationHelper
  def component_page(&block)
    tag.div(class: "p-5") do
      capture(&block)
    end
  end

  def title(text)
    tag.h1(class: "text-3xl font-semibold mb-6") { text }
  end

  def example(**attrs)
    tag
      .div(
        **attrs,
        class: class_names(["flex gap-2 justify-center items-center py-20 px-5 w-full rounded border", attrs[:class]])
      ) do
        yield
      end
  end

  def code_example(str)
    formatter = Rouge::Formatters::HTML.new
    lexer = Rouge::Lexers::ERB.new

    tag.div(class: "bg-[#f7f8fa] dark:bg-[#161b22] divide-y border rounded overflow-hidden", data: { controller: "copy-to-clipboard" }) do
      concat(
        tag.div(class: "px-1 py-1 flex w-full") do
          concat ik_ghost_button(icon: :copy, size: :xs, data: { copy_to_clipboard_target: "button", action: "copy-to-clipboard#copy" }) { "Copy" }
          concat ik_ghost_button(icon: :check, size: :xs, data: { copy_to_clipboard_target: "successMessage"}, class: "hidden") { "Copied!" }
        end
      )

      concat(
        tag.pre(class: "text-sm highlight py-3 px-4 font-mono overflow-scroll", data: { copy_to_clipboard_target: "source" }) do
          tag.code do
            formatter.format(lexer.lex(str.strip_heredoc.strip)).html_safe
          end
        end
      )
    end
  end
end
