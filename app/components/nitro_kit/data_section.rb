# frozen_string_literal: true

module NitroKit
  class DataSection < Component
    Child = Data.define(:component, :content)

    def initialize(
      title:,
      description: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title = validate_text!(:title, title)
      @description = validate_optional_text!(:description, description)
      @actions = nil
      @content = nil

      super(
        component: :data_section,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :title, :description

    def view_template
      yield self if block_given?
      raise ArgumentError, "DataSection requires exactly one Table or EmptyState" unless @content

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          div(**slot_attributes(:heading)) do
            h2(**slot_attributes(:title)) { plain(title) }
            p(**slot_attributes(:description)) { plain(description) } if description
          end
          render_in_slot(@actions.component, :actions, &@actions.content) if @actions
        end
        render_in_slot(@content.component, content_slot, &@content.content)
      end
    end

    def actions(component, &content)
      unless component.is_a?(NitroKit::ButtonGroup)
        raise ArgumentError, "DataSection actions must be a NitroKit::ButtonGroup"
      end
      raise ArgumentError, "DataSection accepts at most one actions group" if @actions

      @actions = Child.new(component:, content:)
      nil
    end

    def table(component, &content)
      assign_content(component, NitroKit::Table, "Table", &content)
    end

    def empty_state(component, &content)
      if component.is_a?(NitroKit::EmptyState) && component.level != 3
        raise ArgumentError, "DataSection EmptyState must use level: 3"
      end

      assign_content(component, NitroKit::EmptyState, "EmptyState", &content)
    end

    private

    def assign_content(component, type, name, &content)
      unless component.is_a?(type)
        raise ArgumentError, "DataSection #{name.underscore} must be a NitroKit::#{name}"
      end
      raise ArgumentError, "DataSection accepts exactly one Table or EmptyState" if @content

      @content = Child.new(component:, content:)
      nil
    end

    def content_slot
      @content.component.is_a?(NitroKit::Table) ? :table : :empty_state
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
