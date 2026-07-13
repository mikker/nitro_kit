# frozen_string_literal: true

module NitroKit
  class Input < Component
    TYPES = %i[
      button checkbox color date datetime-local email file hidden month number password radio
      range search tel text time url week
    ].freeze

    def initialize(
      type: :text,
      id: nil,
      name: nil,
      value: nil,
      placeholder: nil,
      disabled: false,
      readonly: false,
      required: false,
      autocomplete: nil,
      min: nil,
      max: nil,
      step: nil,
      multiple: false,
      accept: nil,
      pattern: nil,
      inputmode: nil,
      checked: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      normalized_type = type.to_s.tr("_", "-").to_sym
      @type = validate_choice!(:type, normalized_type, TYPES)
      disabled = validate_boolean!(:disabled, disabled)
      readonly = validate_boolean!(:readonly, readonly)
      required = validate_boolean!(:required, required)
      multiple = validate_boolean!(:multiple, multiple)
      checked = validate_boolean!(:checked, checked, allow_nil: true)

      native_attributes = {
        type: @type,
        id:,
        name:,
        value: @type == :file ? nil : value,
        placeholder:,
        disabled:,
        readonly:,
        required:,
        autocomplete:,
        min:,
        max:,
        step:,
        multiple:,
        accept:,
        pattern:,
        inputmode:,
        checked:
      }.compact
      native_attributes[:value] = nil if @type == :file

      super(
        component: :input,
        attributes: native_attributes,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :type

    def view_template
      input(**root_attributes)
    end
  end
end
