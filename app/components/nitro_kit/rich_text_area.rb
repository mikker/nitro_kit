# frozen_string_literal: true

module NitroKit
  class RichTextArea < Component
    def initialize(content, id: nil, data: {}, aria: {}, html: {}, desperately_need_a_class: nil)
      raise ArgumentError, "content is required" if content.nil?

      @content = content
      super(component: :rich_text_area, attributes: { id: }.compact, data:, aria:, html:, desperately_need_a_class:)
    end

    def view_template
      div(**root_attributes) { raw(@content) }
    end
  end
end
