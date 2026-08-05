# frozen_string_literal: true

module NitroKit
  class Sheet < Component
    SIDES = %i[left right].freeze
    SIZES = %i[sm md lg].freeze

    Trigger = Data.define(:text, :variant, :size, :icon, :icon_end, :label, :disabled, :html, :aria, :data, :content)
    private_constant :Trigger

    Panel = Data.define(:title, :description, :content)
    private_constant :Panel

    def initialize(
      id:,
      side: :right,
      size: :md,
      close_label: I18n.t("nitro_kit.sheet.close"),
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      unless id.is_a?(String) && id.present? && !id.match?(/\s/)
        raise ArgumentError, "Sheet id: must be a non-blank String without whitespace"
      end
      unless close_label.is_a?(String) && close_label.present?
        raise ArgumentError, "Sheet close_label: must be a non-blank String"
      end

      @id = id
      @side = validate_choice!(:side, side, SIDES)
      @size = validate_choice!(:size, size, SIZES)
      @close_label = close_label

      super(
        component: :sheet,
        attributes: {
          id:,
          data: {
            controller: "nk--dialog",
            action: [
              "click->nk--dialog#invoke",
              "turbo:before-cache@document->nk--dialog#closeForCache"
            ].join(" "),
            side: @side,
            nk__dialog_dismissible_value: true
          }
        },
        html:,
        aria:,
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :id, :side, :size

    def view_template(&declarations)
      collect_declarations(&declarations)

      div(**root_attributes) do
        render_trigger
        render_panel
      end
    end

    def trigger(
      text = nil,
      variant: :default,
      size: :md,
      icon: nil,
      icon_end: nil,
      label: nil,
      disabled: false,
      html: {},
      aria: {},
      data: {},
      &content
    )
      ensure_collecting!
      raise ArgumentError, "Sheet accepts exactly one trigger" if @trigger

      @trigger = Trigger.new(
        text:,
        variant:,
        size:,
        icon:,
        icon_end:,
        label:,
        disabled: validate_boolean!(:disabled, disabled),
        html:,
        aria:,
        data:,
        content:
      )
      nil
    end

    def panel(title:, description: nil, &content)
      ensure_collecting!
      raise ArgumentError, "Sheet accepts exactly one panel" if @panel
      unless title.is_a?(String) && title.present?
        raise ArgumentError, "Sheet title: must be a non-blank String"
      end
      unless description.nil? || (description.is_a?(String) && description.present?)
        raise ArgumentError, "Sheet description: must be nil or a non-blank String"
      end

      @panel = Panel.new(title:, description:, content:)
      nil
    end

    private

    def collect_declarations
      raise ArgumentError, "Sheet requires a declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "Sheet requires exactly one trigger" unless @trigger
      raise ArgumentError, "Sheet requires exactly one panel" unless @panel
    ensure
      @collecting = false
    end

    def render_trigger
      button = Button.new(
        @trigger.text,
        variant: @trigger.variant,
        size: @trigger.size,
        icon: @trigger.icon,
        icon_end: @trigger.icon_end,
        label: @trigger.label,
        disabled: @trigger.disabled,
        html: command_attributes(@trigger.html, "show-modal", disabled: @trigger.disabled),
        aria: @trigger.aria.merge(haspopup: "dialog"),
        data: command_data(@trigger.data, "show-modal", disabled: @trigger.disabled)
      )

      render_in_slot(button, :trigger, &@trigger.content)
    end

    def render_panel
      dialog(
        **slot_attributes(
          :panel,
          attributes: {
            id: panel_id,
            closedby: "any",
            aria: {
              labelledby: title_id,
              describedby: @panel.description ? description_id : nil
            }.compact,
            data: {
              nk__dialog_target: "panel",
              action: "click->nk--dialog#dismiss cancel->nk--dialog#cancel close->nk--dialog#restoreFocus"
            }
          }
        )
      ) do
        render_close
        h2(**slot_attributes(:title, attributes: { id: title_id })) { @panel.title }
        if @panel.description
          p(**slot_attributes(:description, attributes: { id: description_id })) { @panel.description }
        end
        div(**slot_attributes(:body)) { render(@panel.content) } if @panel.content
      end
    end

    def render_close
      render_in_slot(
        Button.new(
          icon: :x,
          label: @close_label,
          variant: :ghost,
          size: :sm,
          html: command_attributes({}, "close"),
          data: command_data({}, "close")
        ),
        :close
      )
    end

    def command_attributes(html, command, disabled: false)
      unless html.is_a?(Hash)
        raise ArgumentError, "html must be a Hash"
      end
      if html.keys.any? { |key| %w[command commandfor].include?(key.to_s.downcase) }
        raise ArgumentError, "command and commandfor are owned by Sheet"
      end

      disabled ? html : html.merge(command:, commandfor: panel_id)
    end

    def command_data(data, command, disabled: false) = disabled ? data : data.merge(nk__dialog_command: command)

    def panel_id = "#{id}-panel"
    def title_id = "#{id}-title"
    def description_id = "#{id}-description"

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "Sheet declarations must be inside the render block"
    end
  end
end
