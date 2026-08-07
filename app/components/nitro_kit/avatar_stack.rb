# frozen_string_literal: true

module NitroKit
  class AvatarStack < Component
    SIZES = Avatar::SIZES

    Overflow = ::Data.define(:count, :label, :html, :aria, :data, :css_class)
    private_constant :Overflow

    def initialize(
      label:,
      size: :md,
      max: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      unless label.is_a?(String) && label.present?
        raise ArgumentError, "AvatarStack label: must be a non-blank String"
      end
      raise ArgumentError, "aria must be a Hash" unless aria.is_a?(Hash)
      if aria.keys.any? { |key| key.to_s.downcase.tr("_", "-") == "label" }
        raise ArgumentError, "AvatarStack group label is owned by label:"
      end
      unless max.nil? || (max.is_a?(Integer) && max.positive?)
        raise ArgumentError, "max must be a positive Integer or nil"
      end

      @size = validate_choice!(:size, size, SIZES)
      @max = max
      @avatars = []
      @overflow = nil

      super(
        component: :avatar_stack,
        attributes: { id:, role: "group" },
        html:,
        aria: aria.merge(label:),
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :size, :max

    def view_template(&block)
      collect_declarations(&block)

      visible, hidden = partition_avatars

      span(**root_attributes) do
        visible.each { |avatar| render_in_slot(avatar, :avatar) }
        render_overflow(overflow_declaration(hidden))
      end
    end

    def avatar(
      src: nil,
      alt: "",
      fallback: nil,
      decorative: false,
      loading: "lazy",
      decoding: "async",
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      ensure_collecting!

      @avatars << Avatar.new(
        src:,
        alt:,
        fallback:,
        decorative:,
        size:,
        loading:,
        decoding:,
        id:,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
      nil
    end

    def overflow(
      count,
      label: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      ensure_collecting!
      raise ArgumentError, "AvatarStack accepts at most one overflow" if @overflow
      if max
        raise ArgumentError, "AvatarStack max: already owns the overflow indicator"
      end
      unless count.is_a?(Integer) && count.positive?
        raise ArgumentError, "count must be a positive Integer"
      end
      raise ArgumentError, "label must be a String or nil" unless label.nil? || label.is_a?(String)
      raise ArgumentError, "aria must be a Hash" unless aria.is_a?(Hash)
      if aria.keys.any? { |key| key.to_s.downcase.tr("_", "-") == "label" }
        raise ArgumentError, "AvatarStack overflow label is owned by label:"
      end

      @overflow = Overflow.new(
        count:,
        label:,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    private

    def collect_declarations
      return unless block_given?

      @collecting = true
      yield(self)
    ensure
      @collecting = false
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "AvatarStack items must be declared inside the render block"
    end

    def partition_avatars
      return [ @avatars, [] ] unless max

      [ @avatars.first(max), @avatars.drop(max) ]
    end

    def overflow_declaration(hidden)
      return @overflow unless max
      return nil if hidden.empty?

      Overflow.new(count: hidden.size, label: nil, html: {}, aria: {}, data: {}, css_class: nil)
    end

    def render_overflow(declaration)
      return unless declaration

      span(
        **slot_attributes(
          :overflow,
          attributes: { role: "img" },
          html: declaration.html,
          aria: declaration.aria.merge(
            label: declaration.label || I18n.t("nitro_kit.avatar_stack.overflow", count: declaration.count)
          ),
          data: declaration.data,
          desperately_need_a_class: declaration.css_class
        )
      ) { "+#{declaration.count}" }
    end
  end
end
