module ApplicationHelper
  def component_page(&block)
    content_tag(:div, class: "py-12 px-5") do
      capture(&block)
    end
  end

  def title(text)
    content_tag(:h1, text, class: "text-3xl font-semibold mb-6")
  end
end
