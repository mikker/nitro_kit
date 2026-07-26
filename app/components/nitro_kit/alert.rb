# frozen_string_literal: true

module NitroKit
  class Alert < Component
    VARIANTS = %i[default info success warning error].freeze

    # The palette family each semantic variant borrows in `palette.css`.
    # Alert owns this mapping; it is not the Badge color axis.
    VARIANT_PALETTE = {
      default: :zinc,
      info: :blue,
      success: :green,
      warning: :amber,
      error: :red
    }.freeze

    LIVE_MODES = %i[off polite assertive].freeze

    Child = ::Data.define(:component, :content)
    private_constant :Child

    def initialize(
      variant: :default,
      title: nil,
      description: nil,
      live: :off,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @variant = validate_choice!(:variant, variant, VARIANTS)
      @live = validate_choice!(:live, live, LIVE_MODES)
      @title_content = content_from_keyword(:title, title)
      @description_content = content_from_keyword(:description, description)
      @icon = nil

      super(
        component: :alert,
        attributes: { id:, role: live_role },
        html:,
        aria:,
        data:,
        variant:,
        desperately_need_a_class:
      )
    end

    attr_reader :variant

    def view_template(&block)
      collect_declarations(&block)

      div(**root_attributes) do
        render_in_slot(@icon.component, :icon, &@icon.content) if @icon
        if @title_content
          div(**slot_attributes(:title)) { render_deferred_content(@title_content) }
        end
        if @description_content
          div(**slot_attributes(:description)) { render_deferred_content(@description_content) }
        end
      end
    end

    def icon(component, &content)
      ensure_collecting!
      unless component.is_a?(NitroKit::Icon)
        raise ArgumentError, "Alert icon must be a NitroKit::Icon"
      end
      raise ArgumentError, "Alert accepts at most one icon" if @icon

      @icon = Child.new(component:, content:)
      nil
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

      raise ArgumentError, "Alert declarations must be inside the render block"
    end

    def live_role
      { off: nil, polite: "status", assertive: "alert" }.fetch(@live)
    end
  end
end
