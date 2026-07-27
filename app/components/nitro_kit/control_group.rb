# frozen_string_literal: true

module NitroKit
  class ControlGroup < Component
    def initialize(label: nil, id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      unless label.nil? || (label.is_a?(String) && label.present?)
        raise ArgumentError, "ControlGroup label: must be nil or a non-blank String"
      end

      super(
        component: :control_group,
        attributes: {
          id:,
          role: label ? "group" : nil,
          aria: { label: }.compact
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      raise ArgumentError, "ControlGroup requires a block" unless block_given?

      @rendering = true
      div(**root_attributes) { yield(self) }
    ensure
      @rendering = false
    end

    def addon(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      raise ArgumentError, "ControlGroup addon must be declared inside the render block" unless @rendering
      raise ArgumentError, "ControlGroup addon accepts text or a block, not both" if text && block
      unless block || (text.is_a?(String) && text.present?)
        raise ArgumentError, "ControlGroup addon requires non-blank text or a block"
      end

      span(**slot_attributes(:addon, html:, aria:, data:, desperately_need_a_class:)) do
        text_or_block(text, &block)
      end
    end
  end
end
