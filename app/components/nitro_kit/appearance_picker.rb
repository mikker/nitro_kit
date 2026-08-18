# frozen_string_literal: true

module NitroKit
  class AppearancePicker < Component
    PRESENTATIONS = %i[segmented radios select dropdown].freeze
    PREFERENCES = %i[light dark system].freeze
    ICONS = {
      light: :sun,
      dark: :moon,
      system: :monitor
    }.freeze

    def initialize(
      id:,
      label: I18n.t("nitro_kit.appearance_picker.label"),
      label_visible: true,
      presentation: :segmented,
      preference: :system,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = validate_id!("AppearancePicker id", id)
      @label = validate_label!(label)
      @label_visible = validate_boolean!(:label_visible, label_visible)
      @presentation = validate_choice!(:presentation, presentation, PRESENTATIONS)
      @preference = validate_choice!(:preference, preference, PREFERENCES)
      if !@label_visible && @presentation != :segmented
        raise ArgumentError,
          "AppearancePicker label_visible: false requires the segmented presentation"
      end

      super(
        component: :appearance_picker,
        attributes: {
          id: @identifier,
          # Browsers give legends special layout, so a hidden label omits the
          # element entirely and the fieldset keeps its name through ARIA.
          aria: @label_visible ? {} : { label: @label },
          data: {
            controller: "nk--appearance",
            presentation: @presentation,
            state: @preference,
            action: "change->nk--appearance#select nitro-kit:appearance-change@window->nk--appearance#synchronize"
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :preference

    def view_template
      return render_select if @presentation == :select
      return render_dropdown if @presentation == :dropdown

      fieldset(**root_attributes) do
        legend(**slot_attributes(:legend)) { plain(@label) } if @label_visible
        div(**slot_attributes(:options)) do
          PREFERENCES.each { |preference| render_option(preference) }
        end
      end
    end

    private

    def preference_label(preference)
      I18n.t("nitro_kit.appearance_picker.preferences.#{preference}")
    end

    def render_dropdown
      div(**root_attributes) do
        render Dropdown.new(id: "#{identifier}-dropdown", placement: :bottom_end) do |menu|
          menu.trigger(
            variant: :ghost,
            icon: ICONS.fetch(@preference),
            label: @label,
            data: { nk__appearance_target: "trigger" }
          )
          menu.title(@label)
          PREFERENCES.each do |option|
            menu.item(
              preference_label(option),
              icon: ICONS.fetch(option),
              data: {
                appearance_preference: option,
                nk__appearance_target: "input",
                action: "click->nk--appearance#select"
              }
            )
          end
        end
      end
    end

    def render_select
      label(**root_attributes) do
        span(**slot_attributes(:legend)) { plain(@label) }
        select(
          **slot_attributes(
            :select,
            data: {
              nk__appearance_target: "input",
              action: "change->nk--appearance#select"
            }
          )
        ) do
          PREFERENCES.each do |value|
            option(value:, selected: value == @preference) do
              plain(preference_label(value))
            end
          end
        end
      end
    end

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
              checked: preference == @preference,
              data: { nk__appearance_target: "input" }
            }
          )
        )
        span(**slot_attributes(:label)) { plain(preference_label(preference)) }
      end
    end

    def option_id(preference)
      "#{identifier}-#{preference}"
    end

    def validate_label!(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "AppearancePicker label must be a non-blank String"
    end
  end
end
