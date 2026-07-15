# frozen_string_literal: true

module NitroKit
  class Dialog < Component
    Trigger = Data.define(:text, :variant, :size, :disabled, :html, :aria, :data, :css_class, :content)
    Panel = Data.define(:title, :description, :nonmodal, :html, :aria, :data, :css_class, :content)

    alias :html_dialog :dialog

    def initialize(
      id:,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      unless id.is_a?(String) && id.present? && !id.match?(/\s/)
        raise ArgumentError, "Dialog id: must be a non-blank String without whitespace"
      end

      @id = id

      super(
        component: :dialog,
        attributes: { id: },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :id

    def view_template(&block)
      collect_declarations(&block)

      div(**root_attributes) do
        render_trigger if @trigger
        render_panel
      end
    end

    def trigger(
      text = nil,
      variant: :default,
      size: :md,
      disabled: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      ensure_collecting!
      raise ArgumentError, "Dialog accepts at most one trigger" if @trigger

      @trigger = Trigger.new(
        text:,
        variant:,
        size:,
        disabled: validate_boolean!(:disabled, disabled),
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class,
        content:
      )
      nil
    end

    def dialog(
      title:,
      description: nil,
      nonmodal: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      ensure_collecting!
      raise ArgumentError, "Dialog accepts exactly one panel" if @panel

      unless title.is_a?(String) && title.present?
        raise ArgumentError, "Dialog title: must be a non-blank String"
      end
      unless description.nil? || (description.is_a?(String) && description.present?)
        raise ArgumentError, "Dialog description: must be nil or a non-blank String"
      end

      @panel = Panel.new(
        title:,
        description:,
        nonmodal: validate_boolean!(:nonmodal, nonmodal),
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class,
        content:
      )
      nil
    end

    def close_button(
      label: "Close dialog",
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      ensure_rendering_panel!
      raise ArgumentError, "Dialog accepts at most one close button" if @close_button_rendered

      @close_button_rendered = true
      render_in_slot(
        Button.new(
          icon: :x,
          variant: :ghost,
          size: :sm,
          html: with_command(html, "close"),
          aria: aria.merge(label:),
          data:,
          desperately_need_a_class:
        ),
        :close
      )
    end

    private

    def collect_declarations
      raise ArgumentError, "Dialog requires a declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "Dialog requires exactly one panel" unless @panel
    ensure
      @collecting = false
    end

    def render_trigger
      component = Button.new(
        @trigger.text,
        variant: @trigger.variant,
        size: @trigger.size,
        disabled: @trigger.disabled,
        html: with_command(@trigger.html, "show-modal", disabled: @trigger.disabled),
        aria: @trigger.aria.merge(haspopup: "dialog"),
        data: @trigger.data,
        desperately_need_a_class: @trigger.css_class
      )

      if @trigger.content
        render_in_slot(component, :trigger) { render(@trigger.content) }
      else
        render_in_slot(component, :trigger)
      end
    end

    def render_panel
      owned_aria = {
        labelledby: element_id(:title),
        describedby: @panel.description.nil? ? nil : element_id(:description)
      }.compact

      html_dialog(
        **slot_attributes(
          :panel,
          attributes: {
            id: element_id(:panel),
            open: @panel.nonmodal,
            aria: owned_aria
          },
          html: @panel.html,
          aria: @panel.aria,
          data: @panel.data,
          desperately_need_a_class: @panel.css_class
        )
      ) do
        render_title
        render_description if @panel.description
        render_panel_content
      end
    end

    def render_panel_content
      return unless @panel.content

      @close_button_rendered = false
      @rendering_panel = true
      render(@panel.content)
    ensure
      @rendering_panel = false
    end

    def render_title
      h2(
        **slot_attributes(
          :title,
          attributes: { id: element_id(:title) }
        )
      ) { @panel.title }
    end

    def render_description
      div(
        **slot_attributes(
          :description,
          attributes: { id: element_id(:description) }
        )
      ) { @panel.description }
    end

    def element_id(suffix)
      "#{id}-#{suffix}"
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "Dialog declarations must be inside the render block"
    end

    def ensure_rendering_panel!
      return if @rendering_panel

      raise ArgumentError, "Dialog close button must be declared inside the panel block"
    end

    def with_command(html, command, disabled: false)
      unless html.is_a?(Hash)
        raise ArgumentError, "html must be a Hash"
      end

      collision = html.keys.find { |key| %w[command commandfor].include?(key.to_s.downcase) }
      if collision
        raise ArgumentError, "#{collision}: is owned by Dialog"
      end

      disabled ? html : html.merge(command:, commandfor: element_id(:panel))
    end
  end
end
