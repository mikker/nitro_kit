# frozen_string_literal: true

module NitroKit
  class RichTextArea < Component
    def initialize(content, id: nil, data: {}, aria: {}, html: {}, desperately_need_a_class: nil)
      @content = validate_content!(content)

      super(component: :rich_text_area, attributes: { id: }.compact, data:, aria:, html:, desperately_need_a_class:)
    end

    attr_reader :content

    def view_template
      div(**root_attributes) do
        div(**slot_attributes(:editor)) { raw(content) }
      end
    end

    private

    # The host application's rich-text helper owns the editor markup. Nitro
    # only wraps it, so it must already be trusted output rather than a String
    # this component would have to escape or mark safe on the caller's behalf.
    def validate_content!(content)
      raise ArgumentError, "content is required" if content.nil?
      return content if content.is_a?(ActiveSupport::SafeBuffer) && content.html_safe?

      raise ArgumentError, "RichTextArea content must be an ActiveSupport::SafeBuffer"
    end
  end
end
