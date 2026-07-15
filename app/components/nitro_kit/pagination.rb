# frozen_string_literal: true

module NitroKit
  class Pagination < Component
    Item = Data.define(:kind, :button, :content, :current, :label)
    class CurrentPage < Component
      def initialize(text, id:, html:, aria:, data:, desperately_need_a_class:)
        @text = text
        super(
          component: :button,
          attributes: { id: },
          html:,
          aria:,
          data:,
          variant: :ghost,
          size: :sm,
          desperately_need_a_class:
        )
      end

      def view_template(&block)
        span(**root_attributes) do
          span(**slot_attributes(:label)) { block ? yield : plain(@text.to_s) }
        end
      end
    end
    private_constant :CurrentPage
    ITEM_KINDS = %i[previous page ellipsis next].freeze

    def initialize(
      label: "Pagination",
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      validate_label!(label, name: "label")
      validate_aria!(aria, reserved: %w[label])
      @items = []

      super(
        component: :pagination,
        attributes: { id: },
        html:,
        aria: aria.merge(label:),
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      yield self if block_given?
      validate_collection!

      nav(**root_attributes) do
        ol(**slot_attributes(:list)) do
          @items.each { |item| render_item(item) }
        end
      end
    end

    def prev(
      text = "Previous",
      href: nil,
      icon: "arrow-left",
      disabled: false,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      text = nil if content && text == "Previous"
      validate_boolean!(:disabled, disabled)
      append_navigation_item(
        :previous,
        text:,
        href:,
        icon:,
        disabled: disabled || missing_href?(href),
        default_label: "Previous page",
        id:,
        html:,
        aria:,
        data:,
        desperately_need_a_class:,
        &content
      )
    end

    def page(
      text = nil,
      href: nil,
      current: false,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      validate_boolean!(:current, current)
      if !text.nil? && content
        raise ArgumentError, "Pagination page accepts text or a block, not both"
      end
      validate_content!(text, content, name: "page label")
      if missing_href?(href) && !current
        raise ArgumentError, "Pagination page href is required unless the page is current"
      end
      validate_aria!(aria, reserved: %w[current disabled])

      item_aria = current ? aria.merge(current: "page") : aria
      button = if current && missing_href?(href)
        CurrentPage.new(
          text,
          id:,
          html:,
          aria: item_aria,
          data:,
          desperately_need_a_class:
        )
      else
        pagination_button(
          text,
          href:,
          disabled: false,
          id:,
          html:,
          aria: item_aria,
          data:,
          desperately_need_a_class:
        )
      end

      append(Item.new(kind: :page, button:, content:, current:, label: nil))
    end

    def ellipsis(label: "More pages")
      validate_label!(label, name: "ellipsis label")

      append(Item.new(kind: :ellipsis, button: nil, content: nil, current: false, label:))
    end

    def next(
      text = "Next",
      href: nil,
      icon: "arrow-right",
      disabled: false,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      text = nil if content && text == "Next"
      validate_boolean!(:disabled, disabled)
      append_navigation_item(
        :next,
        text:,
        href:,
        icon_right: icon,
        disabled: disabled || missing_href?(href),
        default_label: "Next page",
        id:,
        html:,
        aria:,
        data:,
        desperately_need_a_class:,
        &content
      )
    end

    private

    def append_navigation_item(
      kind,
      text:,
      href:,
      icon: nil,
      icon_right: nil,
      disabled:,
      default_label:,
      id:,
      html:,
      aria:,
      data:,
      desperately_need_a_class:,
      &content
    )
      validate_content!(text, content, icon || icon_right, name: "#{kind} label or icon")
      validate_aria!(aria, reserved: %w[disabled current])
      item_aria = accessible_item_aria(aria, text:, content:, default_label:)

      button = pagination_button(
        text,
        href:,
        icon:,
        icon_right:,
        disabled:,
        id:,
        html:,
        aria: item_aria,
        data:,
        desperately_need_a_class:
      )

      append(Item.new(kind:, button:, content:, current: false, label: nil))
    end

    def pagination_button(
      text,
      href:,
      disabled:,
      icon: nil,
      icon_right: nil,
      id:,
      html:,
      aria:,
      data:,
      desperately_need_a_class:
    )
      Button.new(
        text,
        href: missing_href?(href) ? "#" : href,
        variant: :ghost,
        size: :sm,
        icon:,
        icon_right:,
        id:,
        disabled:,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def append(item)
      validate_choice!(:item_kind, item.kind, ITEM_KINDS)

      case item.kind
      when :previous
        raise ArgumentError, "Pagination accepts at most one previous item" if @items.any? { |entry| entry.kind == :previous }
        raise ArgumentError, "Pagination previous must be the first item" if @items.any?
      when :next
        raise ArgumentError, "Pagination accepts at most one next item" if @items.any? { |entry| entry.kind == :next }
      else
        raise ArgumentError, "Pagination next must be the last item" if @items.any? { |entry| entry.kind == :next }
      end

      if item.current && @items.any?(&:current)
        raise ArgumentError, "Pagination accepts at most one current page"
      end

      @items << item
      nil
    end

    def render_item(item)
      li(
        **slot_attributes(
          :item,
          attributes: { data: { kind: item.kind } }
        )
      ) do
        if item.kind == :ellipsis
          render_ellipsis(item)
        else
          render_in_slot(item.button, item.kind, &item.content)
        end
      end
    end

    def render_ellipsis(item)
      span(**slot_attributes(:ellipsis), aria: { hidden: "true" }) { "…" }
      span(**slot_attributes(:ellipsis_label)) { plain(item.label) }
    end

    def validate_collection!
      raise ArgumentError, "Pagination requires at least one item" if @items.empty?

      @items.each_cons(2) do |left, right|
        if left.kind == :ellipsis && right.kind == :ellipsis
          raise ArgumentError, "Pagination cannot contain consecutive ellipses"
        end
      end

      if @items.any? { |item| item.kind == :ellipsis } && @items.none? { |item| item.kind == :page }
        raise ArgumentError, "Pagination ellipsis requires at least one page"
      end
    end

    def validate_content!(text, content, icon = nil, name:)
      return if content || icon || (!text.nil? && !text.to_s.strip.empty?)

      raise ArgumentError, "Pagination #{name} is required"
    end

    def validate_label!(label, name:)
      return if label.is_a?(String) && !label.strip.empty?

      raise ArgumentError, "Pagination #{name} must be a non-blank String"
    end

    def validate_boolean!(name, value)
      return if value == true || value == false

      raise ArgumentError, "Pagination #{name} must be true or false"
    end

    def validate_aria!(aria, reserved:)
      raise ArgumentError, "aria must be a Hash" unless aria.is_a?(Hash)

      normalized_keys = aria.keys.map { |key| key.to_s.downcase.tr("_", "-") }
      collision = normalized_keys.find { |key| reserved.include?(key) }
      return unless collision

      raise ArgumentError, "Pagination owns aria-#{collision}"
    end

    def accessible_item_aria(aria, text:, content:, default_label:)
      return aria if content || (!text.nil? && !text.to_s.strip.empty?)
      return aria if aria.any? { |key, value| key.to_s.tr("_", "-") == "label" && value.to_s.strip.present? }

      aria.merge(label: default_label)
    end

    def missing_href?(href)
      href.nil? || (href.respond_to?(:empty?) && href.empty?)
    end
  end
end
