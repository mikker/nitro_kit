# frozen_string_literal: true

module NitroKit
  class Dialog < Component
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
        attributes: { id:, data: { controller: "nk--dialog" } },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :id

    def view_template
      div(**root_attributes) { yield }
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
      &block
    )
      render_in_slot(
        Button.new(
          text,
          variant:,
          size:,
          disabled:,
          html:,
          aria:,
          data: with_action(data, "click->nk--dialog#open"),
          desperately_need_a_class:
        ),
        :trigger,
        &block
      )
    end

    alias :html_dialog :dialog

    def dialog(
      title:,
      description: nil,
      open: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      unless title.is_a?(String) && title.present?
        raise ArgumentError, "Dialog title: must be a non-blank String"
      end
      unless description.nil? || (description.is_a?(String) && description.present?)
        raise ArgumentError, "Dialog description: must be nil or a non-blank String"
      end
      open = validate_boolean!(:open, open)

      owned_aria = {
        labelledby: element_id(:title),
        describedby: description.nil? ? nil : element_id(:description)
      }.compact

      html_dialog(
        **slot_attributes(
          :panel,
          attributes: {
            open:,
            data: {
              nk__dialog_target: "dialog",
              action: "click->nk--dialog#clickOutside close->nk--dialog#syncClosed",
              state: open ? "open" : "closed"
            }
          },
          html:,
          aria: aria.merge(owned_aria),
          data:,
          desperately_need_a_class:
        )
      ) do
        title(title)
        description(description) unless description.nil?
        yield if block
      end
    end

    def close_button(
      label: "Close dialog",
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      render_in_slot(
        Button.new(
          icon: :x,
          variant: :ghost,
          size: :sm,
          html:,
          aria: aria.merge(label:),
          data: with_action(data, "click->nk--dialog#close"),
          desperately_need_a_class:
        ),
        :close
      )
    end

    def title(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      h2(
        **slot_attributes(
          :title,
          attributes: { id: element_id(:title) },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { text_or_block(text, &block) }
    end

    def description(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      div(
        **slot_attributes(
          :description,
          attributes: { id: element_id(:description) },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { text_or_block(text, &block) }
    end

    private

    def element_id(suffix)
      "#{id}-#{suffix}"
    end

    def with_action(data, owned_action)
      action_key = data.keys.find { |key| key.to_s.tr("_", "-") == "action" }
      app_action = action_key && data[action_key]
      data.except(action_key).merge(action: [ owned_action, app_action ].compact.join(" "))
    end
  end
end
