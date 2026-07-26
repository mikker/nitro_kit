# frozen_string_literal: true

module NitroKit
  Choice = Data.define(:label, :value, :disabled, :id, :description) do
    def initialize(label:, value:, disabled: false, id: nil, description: nil)
      unless disabled == true || disabled == false
        raise ArgumentError, "disabled must be true or false; received #{disabled.inspect}"
      end
      if label.nil? || label.to_s.strip.empty?
        raise ArgumentError, "choice label cannot be blank"
      end
      if value.nil?
        raise ArgumentError, "choice value cannot be nil"
      end
      if id && (!id.is_a?(String) || id.strip.empty?)
        raise ArgumentError, "choice id must be a non-blank String"
      end
      if description && (!description.is_a?(String) || description.strip.empty?)
        raise ArgumentError, "choice description must be a non-blank String"
      end

      super(label:, value:, disabled:, id:, description:)
    end

    def self.coerce(choice)
      case choice
      when self
        choice
      when Hash
        attributes = choice.symbolize_keys
        unknown_keys = attributes.keys - %i[label value disabled id description]
        if unknown_keys.any?
          raise ArgumentError, "unknown choice attributes: #{unknown_keys.join(", ")}"
        end
        new(
          label: attributes.fetch(:label),
          value: attributes.fetch(:value),
          disabled: attributes.fetch(:disabled, false),
          id: attributes[:id],
          description: attributes[:description]
        )
      when Array
        unless choice.length.between?(1, 2)
          raise ArgumentError,
            "choice arrays hold a label and an optional value; " \
            "pass a Hash to declare disabled, id, or description"
        end

        new(label: choice.fetch(0), value: choice.fetch(1, choice.fetch(0)))
      else
        new(label: choice, value: choice)
      end
    end
  end
end
