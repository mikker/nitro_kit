# frozen_string_literal: true

module NitroKit
  class Dropzone < Component
    # Strings the Stimulus controller needs at runtime. Nitro translates them
    # here and hands them to the controller as Stimulus values so no user-facing
    # English lives in JavaScript.
    CONTROLLER_MESSAGE_KEYS = %w[
      progress_for
      remove_file
      uploading
      uploading_percent
      uploaded
      upload_failed
      ready
      status.empty
      status.selected.one
      status.selected.other
      status.uploading.one
      status.uploading.other
      status.attention.one
      status.attention.other
      status.uploaded.one
      status.uploaded.other
      status.ready.one
      status.ready.other
      errors.upload_failed
      errors.upload_failed_detail
      errors.uploads_in_progress
      errors.failed_files
      errors.too_large
      errors.not_accepted
      errors.max_files.one
      errors.max_files.other
    ].freeze

    def initialize(
      id:,
      name:,
      label: I18n.t("nitro_kit.dropzone.label"),
      description: nil,
      direct_upload: true,
      multiple: false,
      accept: nil,
      max_files: 1,
      max_bytes: nil,
      disabled: false,
      required: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = component_id(id)
      @name = form_name(name)
      @label = required_text(:label, label)
      @description = optional_text(:description, description)
      @direct_upload = validate_boolean!(:direct_upload, direct_upload)
      @multiple = validate_boolean!(:multiple, multiple)
      @accept = optional_text(:accept, accept)
      @max_files = positive_integer(:max_files, max_files)
      @max_bytes = positive_integer(:max_bytes, max_bytes, allow_nil: true)
      @disabled = validate_boolean!(:disabled, disabled)
      @required = validate_boolean!(:required, required)

      if !@multiple && @max_files != 1
        raise ArgumentError, "max_files must be 1 when multiple is false"
      end

      super(
        component: :dropzone,
        attributes: {
          id: @identifier,
          aria: { disabled: @disabled ? true : nil },
          data: {
            controller: @disabled ? nil : "nk--dropzone",
            state: @disabled ? "disabled" : "idle",
            action: @disabled ? nil : dropzone_actions,
            nk__dropzone_direct_upload_value: @direct_upload,
            nk__dropzone_max_files_value: @max_files,
            nk__dropzone_max_bytes_value: @max_bytes,
            nk__dropzone_accept_value: @accept
          }.compact.merge(@disabled ? {} : controller_message_values)
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    # `label:` shadows the Phlex element, which the message region still needs.
    alias :html_label :label

    attr_reader :identifier, :name, :label, :description, :max_files, :max_bytes

    def view_template
      div(**root_attributes) do
        render_message
        render_input
        render_status
        render_error
        render_preview_list
        render_preview_template
      end
    end

    private

    # The `label` element owns the accessible name through `for`, so the input
    # carries no competing `aria-labelledby` and its description is not
    # announced twice.
    def render_message
      html_label(
        **slot_attributes(
          :message,
          attributes: { for: input_id }
        )
      ) do
        strong(**slot_attributes(:title, attributes: { id: title_id })) { plain(@label) }
        span(**slot_attributes(:instruction)) { plain(I18n.t("nitro_kit.dropzone.prompt")) }

        if description
          span(**slot_attributes(:description, attributes: { id: description_id })) { plain(description) }
        end
      end
    end

    def render_input
      input(
        **slot_attributes(
          :input,
          attributes: {
            id: input_id,
            type: "file",
            name:,
            accept: @accept,
            multiple: @multiple,
            disabled: @disabled,
            required: @required,
            aria: {
              describedby: describedby,
              errormessage: error_id
            },
            data: {
              direct_upload_url: @direct_upload ? direct_upload_path : nil,
              nk__dropzone_target: "input",
              action: @disabled ? nil : "change->nk--dropzone#select"
            }.compact
          }
        )
      )
    end

    def render_status
      p(
        **slot_attributes(
          :status,
          attributes: {
            id: status_id,
            role: "status",
            aria: { live: "polite", atomic: true },
            data: { nk__dropzone_target: "status" }
          }
        )
      ) do
        plain(
          @disabled ?
            I18n.t("nitro_kit.dropzone.status.disabled") :
            I18n.t("nitro_kit.dropzone.status.empty")
        )
      end
    end

    def render_error
      p(
        **slot_attributes(
          :error,
          attributes: {
            id: error_id,
            role: "alert",
            hidden: true,
            data: { nk__dropzone_target: "error" }
          }
        )
      )
    end

    def render_preview_list
      ul(
        **slot_attributes(
          :preview_list,
          attributes: {
            hidden: true,
            aria: { label: I18n.t("nitro_kit.dropzone.preview_list") },
            data: { nk__dropzone_target: "previewList" }
          }
        )
      )
    end

    def render_preview_template
      template(
        **slot_attributes(
          :preview_template,
          data: { nk__dropzone_target: "previewTemplate" }
        )
      ) do
        li(**slot_attributes(:preview, attributes: { data: { state: "queued" } })) do
          img(**slot_attributes(:preview_image, attributes: { alt: "", hidden: true }))

          span(**slot_attributes(:file)) do
            strong(**slot_attributes(:file_name))
            small(**slot_attributes(:file_size))
          end

          progress(
            **slot_attributes(
              :progress,
              attributes: {
                max: 100,
                value: 0,
                aria: { label: I18n.t("nitro_kit.dropzone.progress") }
              }
            )
          )
          span(**slot_attributes(:file_status)) { plain(I18n.t("nitro_kit.dropzone.queued")) }
          button(
            **slot_attributes(
              :remove_control,
              attributes: {
                type: "button",
                data: { action: "click->nk--dropzone#remove" }
              }
            )
          ) { plain(I18n.t("nitro_kit.dropzone.remove")) }
        end
      end
    end

    def controller_message_values
      CONTROLLER_MESSAGE_KEYS.to_h do |key|
        [
          :"nk__dropzone_#{key.tr('.', '_')}_value",
          I18n.t("nitro_kit.dropzone.#{key}")
        ]
      end
    end

    def dropzone_actions
      [
        "dragenter->nk--dropzone#dragEnter",
        "dragover->nk--dropzone#dragOver",
        "dragleave->nk--dropzone#dragLeave",
        "drop->nk--dropzone#drop",
        "submit@document->nk--dropzone#submit",
        "turbo:before-cache@document->nk--dropzone#teardown"
      ].join(" ")
    end

    def describedby
      [ status_id, error_id ].join(" ")
    end

    def input_id = "#{identifier}-input"
    def title_id = "#{identifier}-title"
    def description_id
      "#{identifier}-description" if description
    end
    def status_id = "#{identifier}-status"
    def error_id = "#{identifier}-error"

    def direct_upload_path
      routes = direct_upload_routes
      unless routes.respond_to?(:rails_direct_uploads_path)
        raise ArgumentError, "direct_upload: true requires Active Storage routes"
      end

      routes.rails_direct_uploads_path
    end

    def direct_upload_routes
      Rails.application.routes.url_helpers
    end

    def component_id(value)
      return value if value.is_a?(String) && value.present? && !value.match?(/\s/)

      raise ArgumentError, "Dropzone id must be a non-blank String without whitespace"
    end

    def form_name(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Dropzone name must be a non-blank String"
    end

    def required_text(name, value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def optional_text(name, value)
      return value if value.nil? || (value.is_a?(String) && value.present?)

      raise ArgumentError, "#{name} must be nil or a non-blank String"
    end

    def positive_integer(name, value, allow_nil: false)
      return value if allow_nil && value.nil?
      return value if value.is_a?(Integer) && value.positive?

      expected = allow_nil ? "nil or a positive Integer" : "a positive Integer"
      raise ArgumentError, "#{name} must be #{expected}"
    end
  end
end
