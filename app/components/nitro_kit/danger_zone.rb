# frozen_string_literal: true

module NitroKit
  class DangerZone < Component
    TITLE_LEVELS = (1..6).freeze

    Child = Data.define(:component, :content)

    def initialize(
      title: nil,
      description: nil,
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

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          public_send(:"h#{@level}", **slot_attributes(:title)) { render_deferred_content(@title_content) }
          p(**slot_attributes(:description)) { render_deferred_content(@description_content) }
        end
        div(**slot_attributes(:confirmation), &@confirmation)
        render_in_slot(@escape.component, :escape, &@escape.content) if @escape
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
      raise ArgumentError, "DangerZone accepts at most one safe escape action" if @escape

      @escape = Child.new(component:, content:)
      nil
    end
  end
end
