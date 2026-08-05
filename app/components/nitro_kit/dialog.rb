# frozen_string_literal: true

module NitroKit
  class Dialog < Component
    Trigger = ::Data.define(:text, :variant, :size, :disabled, :html, :aria, :data, :css_class, :content)
    private_constant :Trigger

    Panel = ::Data.define(:title, :description, :nonmodal, :html, :aria, :data, :css_class, :content)
    private_constant :Panel

    CloseButton = ::Data.define(:label, :html, :aria, :data, :css_class)
    private_constant :CloseButton

    def initialize(
      id:,
      dismissible: true,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      unless id.is_a?(String) && id.present? && !id.match?(/\s/)
        raise ArgumentError, "Dialog id: must be a non-blank String without whitespace"
      end

      @id = id
      @dismissible = validate_boolean!(:dismissible, dismissible)

      super(
        component: :dialog,
        attributes: {
          id:,
          data: {
            controller: "nk--dialog",
            action: [
              "click->nk--dialog#invoke",
              "turbo:before-cache@document->nk--dialog#closeForCache"
            ].join(" "),
            nk__dialog_dismissible_value: @dismissible
          }
        },
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

    def panel(
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
      label: I18n.t("nitro_kit.dialog.close"),
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      ensure_rendering_panel!
      raise ArgumentError, "Dialog accepts at most one close button" if @close_button
      unless @dismissible
        raise ArgumentError, "Dialog dismissible: false renders no close button"
      end

      @close_button = CloseButton.new(
        label:,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    private

    def collect_declarations
      raise ArgumentError, "Dialog requires a declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "Dialog requires exactly one panel" unless @panel

      if @panel.nonmodal && @trigger
        raise ArgumentError,
          "Dialog nonmodal: true cannot be combined with a trigger; the trigger opens the panel modally"
      end
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
        data: command_data(@trigger.data, "show-modal", disabled: @trigger.disabled),
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

      content = capture_panel_content

      dialog(
        **slot_attributes(
          :panel,
          attributes: {
            id: element_id(:panel),
            open: @panel.nonmodal,
            closedby: @dismissible ? "any" : "none",
            aria: owned_aria,
            data: {
              nk__dialog_target: "panel",
              action: "click->nk--dialog#dismiss cancel->nk--dialog#cancel close->nk--dialog#restoreFocus"
            }
          },
          html: @panel.html,
          aria: @panel.aria,
          data: @panel.data,
          desperately_need_a_class: @panel.css_class
        )
      ) do
        render_close_button if @dismissible
        render_title
        render_description if @panel.description
        raw(safe(content))
      end
    end

    # The panel content is captured first so Nitro owns the rendered order:
    # close button, title, description, then application content. A sticky
    # close button must precede scrolling content in the DOM.
    def capture_panel_content
      return "" unless @panel.content

      @rendering_panel = true
      capture { render(@panel.content) }
    ensure
      @rendering_panel = false
    end

    def render_close_button
      declaration = @close_button || CloseButton.new(
        label: I18n.t("nitro_kit.dialog.close"),
        html: {},
        aria: {},
        data: {},
        css_class: nil
      )

      render_in_slot(
        Button.new(
          icon: :x,
          variant: :ghost,
          size: :sm,
          html: with_command(declaration.html, "close"),
          aria: declaration.aria.merge(label: declaration.label),
          data: command_data(declaration.data, "close"),
          desperately_need_a_class: declaration.css_class
        ),
        :close
      )
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

    def command_data(data, command, disabled: false)
      disabled ? data : data.merge(nk__dialog_command: command)
    end
  end
end
