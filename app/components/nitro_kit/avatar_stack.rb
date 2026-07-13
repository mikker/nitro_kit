# frozen_string_literal: true

module NitroKit
  class AvatarStack < Component
    SIZES = Avatar::SIZES

    def initialize(
      size: :md,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @size = validate_choice!(:size, size, SIZES)

      super(
        component: :avatar_stack,
        attributes: { id:, role: "group" },
        html:,
        aria:,
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :size

    def view_template
      span(**root_attributes) do
        yield self if block_given?
      end
    end

    def avatar(positional_src = nil, **options)
      if options.key?(:size)
        raise ArgumentError, "Avatar size is owned by AvatarStack"
      end

      render_in_slot(Avatar.new(positional_src, size:, **options), :avatar)
    end

    def overflow(
      count,
      label: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      unless count.is_a?(Integer) && count.positive?
        raise ArgumentError, "count must be a positive Integer"
      end
      raise ArgumentError, "label must be a String or nil" unless label.nil? || label.is_a?(String)
      raise ArgumentError, "aria must be a Hash" unless aria.is_a?(Hash)

      aria = aria.reject { |key, _value| key.to_s.tr("_", "-") == "label" }
        .merge(label: label || "#{count} more avatars")

      span(
        **slot_attributes(
          :overflow,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { "+#{count}" }
    end
  end
end
