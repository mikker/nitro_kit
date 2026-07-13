# frozen_string_literal: true

module NitroKit
  class Card < Component
    TITLE_LEVELS = (1..6).freeze

    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      super(
        component: :card,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      article(**root_attributes) { yield }
    end

    def title(text = nil, level: 2, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      validate_choice!(:level, level, TITLE_LEVELS)
      public_send(
        :"h#{level}",
        **slot_attributes(:title, html:, aria:, data:, desperately_need_a_class:)
      ) { text_or_block(text, &block) }
    end

    def body(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      div(**slot_attributes(:body, html:, aria:, data:, desperately_need_a_class:)) do
        text_or_block(text, &block)
      end
    end

    alias :html_footer :footer

    def footer(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      html_footer(**slot_attributes(:footer, html:, aria:, data:, desperately_need_a_class:)) do
        text_or_block(text, &block)
      end
    end

    def divider(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      hr(**slot_attributes(:divider, html:, aria:, data:, desperately_need_a_class:))
    end

    def full_width(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      div(**slot_attributes(:full, html:, aria:, data:, desperately_need_a_class:)) { yield }
    end
  end
end
