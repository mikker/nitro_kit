module LayoutHelper
  def component_page
    tag.div(class: "p-3 sm:p-5") do
      yield
    end
  end

  def component_header
    tag.header(class: "space-y-4") do
      yield
    end
  end

  def title(text = nil, **attrs)
    content_for(:title, text)

    tag.h1(
      **attrs,
      class: class_names("text-xl sm:text-3xl font-semibold", attrs[:class])
    ) do
      text || yield
    end
  end

  def lead(text = nil)
    tag.div(class: "italic text-lg text-gray-600 dark:text-gray-400") do
      text || yield
    end
  end

  def section(**attrs)
    tag.div(
      **attrs,
      class: class_names("mt-8 sm:mt-16 space-y-4", attrs[:class])
    ) do
      yield
    end
  end

  def section_title(text = nil, **attrs, &block)
    tag.h2(**attrs, class: class_names("text-2xl font-semibold mb-4", attrs[:class])) do
      text || yield
    end
  end

end
