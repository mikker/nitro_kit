# frozen_string_literal: true

module NitroKit
  class Datepicker < Component
    def initialize(
      id: nil,
      name: nil,
      value: nil,
      min: nil,
      max: nil,
      step: nil,
      disabled: false,
      readonly: false,
      required: false,
      autocomplete: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      disabled = validate_boolean!(:disabled, disabled)
      readonly = validate_boolean!(:readonly, readonly)
      required = validate_boolean!(:required, required)

      super(
        component: :datepicker,
        attributes: {
          type: "date",
          id:,
          name:,
          value:,
          min:,
          max:,
          step:,
          disabled:,
          readonly:,
          required:,
          autocomplete:
        }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      input(**root_attributes)
    end
  end
end
