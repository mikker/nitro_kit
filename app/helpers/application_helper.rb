# frozen_string_literal: true

module ApplicationHelper
  def example(**attrs)
    tag
      .div(
        **attrs,
        class: class_names(
          [
            "flex flex-wrap gap-2 justify-center items-center min-h-[200px] py-6 sm:py-12 p-3 sm:p-5 w-full rounded border overflow-scroll",

            attrs[:class]
          ]
        )
      ) do
        yield
      end
  end

  def markdown(str)
    Commonmarker
      .to_html(
        str.strip_heredoc,
        options: {
          parse: {smart: true}
        }
      )
      .html_safe
  end
end
