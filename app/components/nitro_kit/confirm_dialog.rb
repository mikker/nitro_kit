# frozen_string_literal: true

module NitroKit
  class ConfirmDialog < Dialog
    def initialize(
      id: "confirm-dialog",
      title: "Confirm action",
      cancel_label: "Cancel",
      confirm_label: "Confirm",
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title = required_text(:title, title)
      @cancel_label = required_text(:cancel_label, cancel_label)
      @confirm_label = required_text(:confirm_label, confirm_label)

      super(
        id:,
        dismissible: false,
        html:,
        aria:,
        data: merge_confirm_data(data),
        desperately_need_a_class:
      )
    end

    def view_template
      super do |dialog|
        dialog.dialog(
          title: @title,
          aria: { describedby: message_id },
          data: {
            nk__confirm_dialog_target: "panel",
            action: "close->nk--confirm-dialog#close"
          }
        ) do
          p(
            id: message_id,
            data: { nk__confirm_dialog_target: "message" }
          )

          div(data: { nk_confirm_dialog: "actions" }) do
            render Button.new(
              @cancel_label,
              data: { action: "click->nk--confirm-dialog#cancel" }
            )
            render Button.new(
              @confirm_label,
              variant: :destructive,
              data: { action: "click->nk--confirm-dialog#accept" }
            )
          end
        end
      end
    end

    private

    def message_id
      "#{id}-message"
    end

    def merge_confirm_data(data)
      unless data.is_a?(Hash)
        raise ArgumentError, "data must be a Hash"
      end

      data = data.dup
      merge_additive_data(data, :controller, "nk--confirm-dialog")
      merge_additive_data(data, :action, "nitro-kit:confirm@document->nk--confirm-dialog#open")
      data
    end

    def merge_additive_data(data, name, owned_value)
      key = data.keys.find { normalized_data_attribute(_1) == name.to_s }
      application_value = data.delete(key) if key
      data[name] = [ owned_value, application_value ].compact.join(" ")
    end

    def required_text(name, value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "ConfirmDialog #{name}: must be a non-blank String"
    end
  end
end
