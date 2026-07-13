# frozen_string_literal: true

module NitroKit
  class DangerZone < Component
    Child = Data.define(:component, :content)

    def initialize(
      title:,
      description:,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title = validate_text!(:title, title)
      @description = validate_text!(:description, description)
      @confirmation = nil
      @escape = nil

      super(
        component: :danger_zone,
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
      raise ArgumentError, "DangerZone requires exactly one confirmation" unless @confirmation
      raise ArgumentError, "DangerZone requires exactly one safe escape action" unless @escape

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          h2(**slot_attributes(:title)) { plain(title) }
          p(**slot_attributes(:impact)) { plain(description) }
        end
        div(**slot_attributes(:confirmation), &@confirmation)
        render_in_slot(@escape.component, :escape, &@escape.content)
      end
    end

    def confirmation(&content)
      raise ArgumentError, "DangerZone confirmation requires a block" unless content
      raise ArgumentError, "DangerZone accepts exactly one confirmation" if @confirmation

      @confirmation = content
      nil
    end

    def escape(component, &content)
      unless component.is_a?(NitroKit::Button)
        raise ArgumentError, "DangerZone escape must be a NitroKit::Button"
      end
      if component.variant == :destructive
        raise ArgumentError, "DangerZone escape cannot use the destructive Button variant"
      end
      raise ArgumentError, "DangerZone accepts exactly one safe escape action" if @escape

      @escape = Child.new(component:, content:)
      nil
    end

    private

    def validate_text!(name, value)
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end
  end
end
