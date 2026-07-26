# frozen_string_literal: true

module NitroKit
  class DataSection < Component
    Child = Data.define(:component, :content)

    def initialize(
      title: nil,
      description: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title_content = content_from_keyword(:title, title)
      @description_content = content_from_keyword(:description, description)
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

    def view_template
      yield self if block_given?
      require_content!("DataSection", :title, @title_content)
      raise ArgumentError, "DataSection requires exactly one table or EmptyState" unless @content

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          div(**slot_attributes(:heading)) do
            h2(**slot_attributes(:title)) { render_deferred_content(@title_content) }
            if @description_content
              p(**slot_attributes(:description)) { render_deferred_content(@description_content) }
            end
          end
          render_in_slot(@actions.component, :actions, &@actions.content) if @actions
        end
        render_in_slot(@content.component, content_slot, &@content.content)
      end
    end

    def title(text = nil, &block)
      @title_content = declare_content(:title, @title_content, text, &block)
      nil
    end

    def description(text = nil, &block)
      @description_content = declare_content(:description, @description_content, text, &block)
      nil
    end

    alias :html_table :table

    def actions(component, &content)
      unless component.is_a?(NitroKit::ButtonGroup) || component.is_a?(NitroKit::Button)
        raise ArgumentError, "DataSection actions must be a NitroKit::ButtonGroup or NitroKit::Button"
      end
      raise ArgumentError, "DataSection accepts at most one actions group" if @actions

      @actions = Child.new(component:, content:)
      nil
    end

    def table(component, &content)
      unless table_component?(component)
        raise ArgumentError, "DataSection table must be a NitroKit::Table or NitroKit::DetailsTable"
      end

      assign_content(component, &content)
    end

    def empty_state(component, &content)
      unless component.is_a?(NitroKit::EmptyState)
        raise ArgumentError, "DataSection empty_state must be a NitroKit::EmptyState"
      end
      raise ArgumentError, "DataSection EmptyState must use level: 3" if component.level != 3

      assign_content(component, &content)
    end

    private

    def table_component?(component)
      component.is_a?(NitroKit::Table) || component.is_a?(NitroKit::DetailsTable)
    end

    def assign_content(component, &content)
      raise ArgumentError, "DataSection accepts exactly one table or EmptyState" if @content

      @content = Child.new(component:, content:)
      nil
    end

    def content_slot
      table_component?(@content.component) ? :table : :empty_state
    end
  end
end
