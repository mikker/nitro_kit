# frozen_string_literal: true

module NitroKit
  class Component < Phlex::HTML
    DeferredContent = Data.define(:text, :block)
    private_constant :DeferredContent
    # Data keys a component sets for itself through `attributes:`.
    COMPONENT_OWNED_DATA_ATTRIBUTES = %w[
      state disabled required orientation presentation placement layout field-type
    ].freeze
    # Every data key Nitro owns. Applications may not pass any of them through `data:`.
    RESERVED_DATA_ATTRIBUTES = (
      %w[nk slot variant size nk-escape enhanced] + COMPONENT_OWNED_DATA_ATTRIBUTES
    ).freeze
    ADDITIVE_DATA_ATTRIBUTES = %w[action controller].freeze
    FORBIDDEN_ATTRIBUTES = %w[class style].freeze

    def initialize(
      component:,
      attributes: {},
      html: {},
      aria: {},
      data: {},
      variant: nil,
      size: nil,
      desperately_need_a_class: nil
    )
      @component_name = normalize_identity(component, name: "component")
      @attrs = owned_attributes(
        attributes:,
        html:,
        aria:,
        data:,
        owned_data: {
          nk: @component_name,
          variant: variant && normalize_identity(variant, name: "variant"),
          size: size && normalize_identity(size, name: "size")
        }.compact,
        desperately_need_a_class:
      )
    end

    private

    def root_attributes
      @attrs
    end

    def slot_attributes(
      slot,
      attributes: {},
      html: {},
      aria: {},
      data: {},
      variant: nil,
      desperately_need_a_class: nil
    )
      raise ArgumentError, "Slots require a component identity" unless @component_name

      owned_attributes(
        attributes:,
        html:,
        aria:,
        data:,
        owned_data: {
          slot: qualified_slot(slot),
          variant: variant && normalize_identity(variant, name: "variant")
        }.compact,
        desperately_need_a_class:
      )
    end

    def render_in_slot(component, slot, &block)
      unless component.is_a?(NitroKit::Component)
        raise ArgumentError, "Slots can only contain NitroKit::Component instances"
      end

      component.__send__(:attach_to_slot!, qualified_slot(slot))
      render(component, &block)
    end

    def validate_choice!(name, value, choices)
      return value if choices.include?(value)

      raise ArgumentError, "Unknown #{name} #{value.inspect}; expected one of: #{choices.map(&:inspect).join(", ")}"
    end

    def validate_boolean!(name, value, allow_nil: false)
      return value if value == true || value == false
      return value if allow_nil && value.nil?

      expected = allow_nil ? "true, false, or nil" : "true or false"
      raise ArgumentError, "#{name} must be #{expected}; received #{value.inspect}"
    end

    def owned_attributes(attributes:, html:, aria:, data:, owned_data:, desperately_need_a_class:)
      attributes = attribute_hash(attributes, name: "attributes")
      html = attribute_hash(html, name: "html")
      aria = attribute_hash(aria, name: "aria")
      data = attribute_hash(data, name: "data")

      internal_aria = extract_nested_attributes!(attributes, :aria)
      internal_data = extract_nested_attributes!(attributes, :data)
      internal_aria = normalize_aria_values(internal_aria)
      aria = normalize_aria_values(aria)

      validate_html_attributes!(attributes, source: "attributes")
      validate_html_attributes!(html, source: "html")
      validate_public_data!(data)
      validate_internal_data!(internal_data)

      merged = merge_distinct_attributes(attributes, html)
      merged_aria = merge_distinct_attributes(internal_aria, aria, name: "ARIA")
      merged_data = merge_owned_data(owned_data, internal_data, data)

      merged[:aria] = merged_aria if merged_aria.any?
      merged[:data] = merged_data if merged_data.any?

      unless desperately_need_a_class.nil?
        validate_class_escape!(desperately_need_a_class)
        merged[:class] = desperately_need_a_class
        merged[:data] = merge_owned_data(merged.fetch(:data, {}), { nk_escape: "class" })
      end

      merged
    end

    def attribute_hash(value, name:)
      return value.dup if value.is_a?(Hash)

      raise ArgumentError, "#{name} must be a Hash"
    end

    def extract_nested_attributes!(attributes, name)
      key = attributes.keys.find { |candidate| normalized_attribute(candidate) == name.to_s }
      return {} unless key

      attribute_hash(attributes.delete(key), name:)
    end

    def validate_html_attributes!(attributes, source:)
      attributes.each_key do |key|
        normalized = normalized_attribute(key)

        if FORBIDDEN_ATTRIBUTES.include?(normalized)
          raise ArgumentError, "#{normalized}: is not allowed; use desperately_need_a_class: for classes"
        end

        if normalized == "data" || normalized == "aria" || normalized.start_with?("data-") || normalized.start_with?("aria-")
          boundary = normalized.start_with?("aria") ? "aria" : "data"
          raise ArgumentError, "Pass #{normalized} through #{boundary}:, not #{source}:"
        end
      end
    end

    def validate_public_data!(data)
      data.each_key do |key|
        normalized = normalized_data_attribute(key)
        next unless RESERVED_DATA_ATTRIBUTES.include?(normalized)

        raise ArgumentError, "data-#{normalized} is reserved by Nitro Kit"
      end
    end

    def validate_internal_data!(data)
      base_owned = RESERVED_DATA_ATTRIBUTES - COMPONENT_OWNED_DATA_ATTRIBUTES

      data.each_key do |key|
        normalized = normalized_data_attribute(key)
        next unless base_owned.include?(normalized)

        raise ArgumentError, "Use the component or slot API for data-#{normalized}"
      end
    end

    def merge_distinct_attributes(*hashes, name: "HTML")
      hashes.compact.reduce({}) do |merged, attributes|
        attributes.each do |key, value|
          existing_key = merged.keys.find do |candidate|
            normalized_attribute(candidate) == normalized_attribute(key)
          end

          if existing_key
            raise ArgumentError, "Duplicate #{name} attribute #{normalized_attribute(key)}"
          end

          merged[key] = value
        end

        merged
      end
    end

    def merge_owned_data(*hashes)
      hashes.compact.reduce({}) do |merged, attributes|
        attributes.each do |key, value|
          existing_key = merged.keys.find do |candidate|
            normalized_data_attribute(candidate) == normalized_data_attribute(key)
          end

          if existing_key
            normalized = normalized_data_attribute(key)

            unless ADDITIVE_DATA_ATTRIBUTES.include?(normalized)
              raise ArgumentError, "Duplicate data-#{normalized} attribute"
            end

            merged[existing_key] = [ merged[existing_key], value ].flatten.compact.join(" ")
          else
            merged[key] = value
          end
        end

        merged
      end
    end

    def normalize_identity(value, name:)
      normalized = value.to_s.strip.tr("_", "-")
      raise ArgumentError, "#{name} cannot be blank" if normalized.empty?
      unless normalized.match?(/\A[a-z0-9-]+\z/)
        raise ArgumentError, "#{name} must contain only lowercase letters, numbers, and hyphens"
      end

      normalized
    end

    def qualified_slot(slot)
      raise ArgumentError, "Slots require a component identity" unless @component_name

      slot_name = normalize_identity(slot, name: "slot")
      slot_name.start_with?("#{@component_name}-") ? slot_name : "#{@component_name}-#{slot_name}"
    end

    def attach_to_slot!(slot)
      raise ArgumentError, "Nested slots require a component identity" unless @component_name

      data = @attrs.fetch(:data, {})
      if data.keys.any? { |key| normalized_data_attribute(key) == "slot" }
        raise ArgumentError, "Component is already attached to a slot"
      end

      @attrs = @attrs.merge(data: merge_owned_data(data, { slot: }))
    end

    def normalized_attribute(key)
      key.to_s.downcase.tr("_", "-")
    end

    def normalized_data_attribute(key)
      normalized_attribute(key).delete_prefix("data-")
    end

    def normalized_aria_attribute(key)
      normalized_attribute(key).delete_prefix("aria-")
    end

    # Conventions shared by the labelled control components. They read the
    # `@label`, `@description`, `@id`, `@control_aria`, and `@invalid` state
    # those components already keep.

    def description_id
      "#{@id}-description" if @id && @description
    end

    def control_aria
      attributes = @control_aria.dup
      key = attributes.keys.find { |candidate| normalized_aria_attribute(candidate) == "describedby" }
      attributes[:describedby] = [ attributes.delete(key), description_id ].compact.join(" ").presence
      attributes[:invalid] = "true" if @invalid
      attributes
    end

    def require_accessible_name!(&block)
      labelled = !@label.nil? || !block.nil?

      unless labelled || accessible_name?
        raise ArgumentError, "#{component_words} requires a label, block, or accessible control name"
      end

      if @description && !labelled
        raise ArgumentError, "#{component_words} description requires label text or block content"
      end
    end

    def accessible_name?
      @control_aria.any? do |key, value|
        %w[label labelledby].include?(normalized_aria_attribute(key)) && value.to_s.present?
      end
    end

    def component_words
      @component_name.tr("-", " ")
    end

    def validate_optional_text!(name, text)
      return if text.nil?
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String or nil"
    end

    def normalize_aria_values(attributes)
      attributes.transform_values do |value|
        value == true || value == false ? value.to_s : value
      end
    end

    def validate_class_escape!(value)
      return if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "desperately_need_a_class: must be a non-blank String"
    end

    def text_or_block(text = nil, &block)
      if text && text.is_a?(ActiveSupport::SafeBuffer)
        plain(text)
      elsif text
        text
      elsif block_given?
        yield
      else
        nil
      end
    end

    def content_from_keyword(name, text)
      return if text.nil?

      validate_content_text!(name, text)
      DeferredContent.new(text:, block: nil)
    end

    def declare_content(name, current, text = nil, &block)
      raise ArgumentError, "#{name} has already been provided" if current
      raise ArgumentError, "#{name} accepts text or a block, not both" if !text.nil? && block

      unless block
        validate_content_text!(name, text)
      end

      DeferredContent.new(text:, block:)
    end

    def require_content!(component, name, content)
      return content if content

      raise ArgumentError, "#{component} requires #{name} through the constructor or compound method"
    end

    def render_deferred_content(content)
      text_or_block(content.text, &content.block)
    end

    def validate_content_text!(name, text)
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String or a block"
    end
  end
end
