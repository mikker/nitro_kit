# frozen_string_literal: true

module NitroKit
  class Fieldset < Component
    def initialize(
      legend:,
      description: nil,
      disabled: false,
      name: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @legend = validate_text!(:legend, legend)
      @description = validate_optional_text!(:description, description)
      disabled = validate_boolean!(:disabled, disabled)

      super(
        component: :fieldset,
        attributes: { disabled:, name: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    alias :html_legend :legend

    attr_reader :legend, :description

    def view_template(&block)
      raise ArgumentError, "fieldset requires a block" unless block

      fieldset(**root_attributes) do
        html_legend(**slot_attributes(:legend)) { plain(legend) }
        if description
          p(**slot_attributes(:description)) { plain(description.to_s) }
        end
        div(**slot_attributes(:fields), &block)
      end
    end

    private

    def validate_text!(name, text)
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def validate_optional_text!(name, text)
      return if text.nil?
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String or nil"
    end
  end
end
