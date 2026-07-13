# frozen_string_literal: true

module NitroKit
  class Label < Component
    def initialize(
      text = nil,
      for: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      if !text.nil? && (!text.is_a?(String) || text.strip.empty?)
        raise ArgumentError, "label text must be a non-blank String"
      end
      @text = text

      super(
        component: :label,
        attributes: { for:, id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :text

    def view_template(&block)
      if text.nil? && !block
        raise ArgumentError, "label requires text or a block"
      end

      label(**root_attributes) { text_or_block(text, &block) }
    end
  end
end
