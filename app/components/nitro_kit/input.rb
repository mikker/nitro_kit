# frozen_string_literal: true

module NitroKit
  class Input < Component
    TYPES = %i[
      button checkbox color date datetime-local email file hidden month number password radio
      range search tel text time url week
    ].freeze
    OWNED_ATTRIBUTES = %i[
      type id name value placeholder disabled readonly required autocomplete min max step
      minlength maxlength multiple accept pattern inputmode checked
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
      minlength: nil,
      maxlength: nil,
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
      minlength = validate_non_negative_integer!(:minlength, minlength)
      maxlength = validate_non_negative_integer!(:maxlength, maxlength)
      if minlength && maxlength && minlength > maxlength
        raise ArgumentError, "minlength cannot exceed maxlength"
      end
      if @type == :file && !value.nil?
        raise ArgumentError, "file inputs never carry a value; omit value:"
      end
      reject_owned_attributes!(html)

      super(
        component: :input,
        attributes: {
          type: @type,
          id:,
          name:,
          value:,
          placeholder:,
          disabled:,
          readonly:,
          required:,
          autocomplete:,
          min:,
          max:,
          step:,
          minlength:,
          maxlength:,
          multiple:,
          accept:,
          pattern:,
          inputmode:,
          checked:
        }.compact,
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

    private

    def reject_owned_attributes!(html)
      return unless html.is_a?(Hash)

      html.each_key do |key|
        normalized = key.to_s.downcase.tr("_", "-")
        owned = OWNED_ATTRIBUTES.find { |name| name.to_s.tr("_", "-") == normalized }
        next unless owned

        raise ArgumentError, "#{normalized} is owned by Input; pass #{owned}: as a keyword"
      end
    end

    def validate_non_negative_integer!(name, value)
      return if value.nil?
      return value if value.is_a?(Integer) && value >= 0

      raise ArgumentError, "#{name} must be a non-negative Integer"
    end
  end
end
