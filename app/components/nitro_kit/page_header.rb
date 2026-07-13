# frozen_string_literal: true

module NitroKit
  class PageHeader < Component
    Child = Data.define(:component, :content)

    def initialize(
      title:,
      eyebrow: nil,
      description: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title = validate_text!(:title, title)
      @eyebrow = validate_optional_text!(:eyebrow, eyebrow)
      @description = validate_optional_text!(:description, description)
      @actions = nil

      super(
        component: :page_header,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :title, :eyebrow, :description

    def view_template
      yield self if block_given?

      header(**root_attributes) do
        p(**slot_attributes(:eyebrow)) { plain(eyebrow) } if eyebrow
        h1(**slot_attributes(:title)) { plain(title) }
        p(**slot_attributes(:description)) { plain(description) } if description
        render_in_slot(@actions.component, :actions, &@actions.content) if @actions
      end
    end

    def actions(component, &content)
      unless component.is_a?(NitroKit::ButtonGroup)
        raise ArgumentError, "PageHeader actions must be a NitroKit::ButtonGroup"
      end
      raise ArgumentError, "PageHeader accepts at most one actions group" if @actions

      @actions = Child.new(component:, content:)
      nil
    end

    private

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
