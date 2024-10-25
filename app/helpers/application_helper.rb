module ApplicationHelper
  def component_page(&block)
    tag.div(class: "py-12 px-5") do
      capture(&block)
    end
  end

  def title(text)
    tag.h1(class: "text-3xl font-semibold mb-6") { text }
  end

  def example
    tag.div(class: "flex justify-center items-center py-20 px-5 w-full rounded border") do
      yield
    end
  end
end
