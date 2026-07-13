# frozen_string_literal: true

module NitroKit
  class EmptyState < Component
    Child = Data.define(:component, :content)
    TITLE_LEVELS = (2..6).freeze

    def initialize(
      title:,
      description: nil,
      level: 2,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title = validate_text!(:title, title)
      @description = validate_optional_text!(:description, description)
      @level = validate_choice!(:level, level, TITLE_LEVELS)
      @icon = nil
      @actions = []

      super(
        component: :empty_state,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :title, :description, :level

    def view_template
      yield self if block_given?

      section(**root_attributes) do
        render_in_slot(@icon.component, :icon, &@icon.content) if @icon
        public_send(:"h#{level}", **slot_attributes(:title)) { plain(title) }
        p(**slot_attributes(:description)) { plain(description) } if description
        render_actions if @actions.any?
      end
    end

    def icon(component, &content)
      unless component.is_a?(NitroKit::Icon)
        raise ArgumentError, "EmptyState icon must be a NitroKit::Icon"
      end
      raise ArgumentError, "EmptyState accepts at most one icon" if @icon

      @icon = Child.new(component:, content:)
      nil
    end

    def action(component, &content)
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

    def render_actions
      div(**slot_attributes(:actions)) do
        @actions.each do |action|
          render_in_slot(action.component, :action, &action.content)
        end
      end
    end

    def validate_text!(name, value)
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def validate_optional_text!(name, value)
      return if value.nil?

      validate_text!(name, value)
    end
  end
end
