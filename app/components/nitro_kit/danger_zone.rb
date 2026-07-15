# frozen_string_literal: true

module NitroKit
  class DangerZone < Component
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

    def view_template
      yield self if block_given?
      require_content!("DangerZone", :title, @title_content)
      require_content!("DangerZone", :description, @description_content)
      raise ArgumentError, "DangerZone requires exactly one confirmation" unless @confirmation
      raise ArgumentError, "DangerZone requires exactly one safe escape action" unless @escape

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          h2(**slot_attributes(:title)) { render_deferred_content(@title_content) }
          p(**slot_attributes(:impact)) { render_deferred_content(@description_content) }
        end
        div(**slot_attributes(:confirmation), &@confirmation)
        render_in_slot(@escape.component, :escape, &@escape.content)
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
  end
end
