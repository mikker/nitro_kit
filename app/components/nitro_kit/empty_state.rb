# frozen_string_literal: true

module NitroKit
  class EmptyState < Component
    Child = ::Data.define(:component, :content)
    private_constant :Child

    TITLE_LEVELS = (2..6).freeze
    VARIANTS = %i[default borderless].freeze

    def initialize(
      title: nil,
      description: nil,
      variant: :default,
      level: 2,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title_content = content_from_keyword(:title, title)
      @description_content = content_from_keyword(:description, description)
      @level = validate_choice!(:level, level, TITLE_LEVELS)
      @variant = validate_choice!(:variant, variant, VARIANTS)
      @icon = nil
      @actions = []

      super(
        component: :empty_state,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        variant:,
        desperately_need_a_class:
      )
    end

    attr_reader :level, :variant

    def view_template(&block)
      collect_declarations(&block)
      require_content!("EmptyState", :title, @title_content)

      section(**root_attributes) do
        render_in_slot(@icon.component, :icon, &@icon.content) if @icon
        public_send(:"h#{level}", **slot_attributes(:title)) { render_deferred_content(@title_content) }
        if @description_content
          p(**slot_attributes(:description)) { render_deferred_content(@description_content) }
        end
        render_actions if @actions.any?
      end
    end

    def title(text = nil, &block)
      ensure_collecting!
      @title_content = declare_content(:title, @title_content, text, &block)
      nil
    end

    def description(text = nil, &block)
      ensure_collecting!
      @description_content = declare_content(:description, @description_content, text, &block)
      nil
    end

    def icon(component, &content)
      ensure_collecting!
      unless component.is_a?(NitroKit::Icon)
        raise ArgumentError, "EmptyState icon must be a NitroKit::Icon"
      end
      raise ArgumentError, "EmptyState accepts at most one icon" if @icon

      @icon = Child.new(component:, content:)
      nil
    end

    def action(component, &content)
      ensure_collecting!
      unless component.is_a?(NitroKit::Button)
        raise ArgumentError, "EmptyState actions must be NitroKit::Button instances"
      end
      if @actions.any? { |action| action.component.equal?(component) }
        raise ArgumentError, "EmptyState cannot contain the same Button twice"
      end
      raise ArgumentError, "EmptyState accepts at most two actions" if @actions.size == 2

      @actions << Child.new(component:, content:)
      nil
    end

    private

    def collect_declarations
      return unless block_given?

      @collecting = true
      yield(self)
    ensure
      @collecting = false
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "EmptyState declarations must be inside the render block"
    end

    def render_actions
      div(**slot_attributes(:actions)) do
        @actions.each do |action|
          render_in_slot(action.component, :action, &action.content)
        end
      end
    end
  end
end
