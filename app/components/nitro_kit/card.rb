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
      raise ArgumentError, "Card requires a block" unless block_given?

      article(**root_attributes) { yield }
    end

    alias :html_title :title
    alias :html_body :body
    alias :html_footer :footer

    def title(text = nil, level: 2, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      validate_choice!(:level, level, TITLE_LEVELS)
      require_region!(:title, text, block)
      public_send(
        :"h#{level}",
        **slot_attributes(:title, html:, aria:, data:, desperately_need_a_class:)
      ) { text_or_block(text, &block) }
    end

    def body(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      require_region!(:body, text, block)
      div(**slot_attributes(:body, html:, aria:, data:, desperately_need_a_class:)) do
        text_or_block(text, &block)
      end
    end

    def footer(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      require_region!(:footer, text, block)
      html_footer(**slot_attributes(:footer, html:, aria:, data:, desperately_need_a_class:)) do
        text_or_block(text, &block)
      end
    end

    def divider(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      hr(**slot_attributes(:divider, html:, aria:, data:, desperately_need_a_class:))
    end

    def full(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      raise ArgumentError, "Card full requires a block" unless block_given?

      div(**slot_attributes(:full, html:, aria:, data:, desperately_need_a_class:)) { yield }
    end

    private

    def require_region!(name, text, block)
      return if block
      return if text.respond_to?(:to_str) && !text.to_str.strip.empty?

      raise ArgumentError, "Card #{name} requires non-blank text or a block"
    end
  end
end
