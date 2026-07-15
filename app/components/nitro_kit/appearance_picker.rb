# frozen_string_literal: true

module NitroKit
  class AppearancePicker < Component
    PREFERENCES = %i[light dark system].freeze
    LABELS = {
      light: "Light",
      dark: "Dark",
      system: "System"
    }.freeze

    def initialize(
      id:,
      label: "Appearance",
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = component_id(id)
      @label = validate_label!(label)

      super(
        component: :appearance_picker,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--appearance",
            state: "system",
            action: "change->nk--appearance#select nitro-kit:appearance-change@window->nk--appearance#synchronize"
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier

    def view_template
      fieldset(**root_attributes) do
        legend(**slot_attributes(:legend)) { plain(@label) }
        div(**slot_attributes(:options)) do
          PREFERENCES.each { |preference| render_option(preference) }
        end
      end
    end

    private

    def render_option(preference)
      label(
        **slot_attributes(
          :option,
          attributes: { for: option_id(preference) }
        )
      ) do
        input(
          **slot_attributes(
            :control,
            attributes: {
              id: option_id(preference),
              type: "radio",
              name: "#{identifier}-preference",
              value: preference,
              checked: preference == :system,
              data: { nk__appearance_target: "input" }
            }
          )
        )
        span(**slot_attributes(:label)) { plain(LABELS.fetch(preference)) }
      end
    end

    def option_id(preference)
      "#{identifier}-#{preference}"
    end

    def component_id(value)
      return value if value.is_a?(String) && value.present? && !value.match?(/\s/)

      raise ArgumentError, "AppearancePicker id must be a non-blank String without whitespace"
    end

    def validate_label!(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "AppearancePicker label must be a non-blank String"
    end
  end
end
