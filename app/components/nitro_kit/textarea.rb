# frozen_string_literal: true

module NitroKit
  class Textarea < Component
    WRAPS = %i[soft hard off].freeze

    def initialize(
      id: nil,
      name: nil,
      value: nil,
      placeholder: nil,
      disabled: false,
      readonly: false,
      required: false,
      autocomplete: nil,
      rows: nil,
      cols: nil,
      minlength: nil,
      maxlength: nil,
      wrap: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @value = value
      disabled = validate_boolean!(:disabled, disabled)
      readonly = validate_boolean!(:readonly, readonly)
      required = validate_boolean!(:required, required)
      rows = validate_positive_integer!(:rows, rows)
      cols = validate_positive_integer!(:cols, cols)
      minlength = validate_non_negative_integer!(:minlength, minlength)
      maxlength = validate_non_negative_integer!(:maxlength, maxlength)
      if minlength && maxlength && minlength > maxlength
        raise ArgumentError, "minlength cannot exceed maxlength"
      end
      wrap = validate_choice!(:wrap, wrap.to_s.to_sym, WRAPS) unless wrap.nil?

      native_attributes = {
        id:,
        name:,
        placeholder:,
        disabled:,
        readonly:,
        required:,
        autocomplete:,
        rows:,
        cols:,
        minlength:,
        maxlength:,
        wrap:
      }.compact
      native_attributes.merge!(rows:, cols:, minlength:, maxlength:, wrap:)

      super(
        component: :textarea,
        attributes: native_attributes,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :value

    def view_template
      textarea(**root_attributes) { plain(value.to_s) }
    end

    private

    def validate_positive_integer!(name, value)
      return if value.nil?
      return value if value.is_a?(Integer) && value.positive?

      raise ArgumentError, "#{name} must be a positive Integer"
    end

    def validate_non_negative_integer!(name, value)
      return if value.nil?
      return value if value.is_a?(Integer) && value >= 0

      raise ArgumentError, "#{name} must be a non-negative Integer"
    end
  end
end
