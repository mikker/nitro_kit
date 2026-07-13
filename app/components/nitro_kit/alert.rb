# frozen_string_literal: true

module NitroKit
  class Alert < Component
    VARIANTS = %i[default warning error success].freeze

    def initialize(
      variant: :default,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @variant = validate_choice!(:variant, variant, VARIANTS)

      super(
        component: :alert,
        attributes: { id:, role: "alert" },
        html:,
        aria:,
        data:,
        variant:,
        desperately_need_a_class:
      )
    end

    attr_reader :variant

    def view_template
      div(**root_attributes) do
        yield self if block_given?
      end
    end

    def icon(component, &block)
      render_in_slot(component, :icon, &block)
    end

    def title(
      text = nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      div(
        **slot_attributes(
          :title,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) do
        text_or_block(text, &block)
      end
    end

    def description(
      text = nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      div(
        **slot_attributes(
          :description,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) do
        text_or_block(text, &block)
      end
    end
  end
end
