# frozen_string_literal: true

module NitroKit
  class Pagination < Component
    Item = Data.define(:kind, :button, :current_page, :content, :current, :label)
    CurrentPage = Data.define(:text, :attributes)
    private_constant :CurrentPage
    ITEM_KINDS = %i[previous page ellipsis next].freeze
    UNSET = Object.new.freeze
    private_constant :UNSET

    def initialize(
      label: I18n.t("nitro_kit.pagination.label"),
      pagy: nil,
      page_url: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      validate_label!(label, name: "label")
      validate_aria!(aria, reserved: %w[label])
      validate_pagy!(pagy, page_url:)
      @pagy = pagy
      @page_url = page_url
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

    def view_template(&content)
      if @pagy && content
        raise ArgumentError, "Pagination accepts a Pagy object or a block, not both"
      end

      append_pagy_items if @pagy
      yield self if content
      validate_collection!

      nav(**root_attributes) do
        ol(**slot_attributes(:list)) do
          @items.each { |item| render_item(item) }
        end
      end
    end

    def prev(
      text = UNSET,
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
      text = default_text(text, I18n.t("nitro_kit.pagination.previous"), content)
      validate_boolean!(:disabled, disabled)
      append_navigation_item(
        :previous,
        text:,
        href:,
        icon:,
        disabled: disabled || missing_href?(href),
        default_label: I18n.t("nitro_kit.pagination.previous_page"),
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
      button = nil
      current_page = nil

      if current && missing_href?(href)
        current_page = CurrentPage.new(
          text:,
          attributes: slot_attributes(
            :current,
            attributes: { id: }.compact,
            html:,
            aria: item_aria,
            data:,
            desperately_need_a_class:
          )
        )
      else
        button = pagination_button(
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

      append(Item.new(kind: :page, button:, current_page:, content:, current:, label: nil))
    end

    def ellipsis(label: I18n.t("nitro_kit.pagination.ellipsis"))
      validate_label!(label, name: "ellipsis label")

      append(Item.new(kind: :ellipsis, button: nil, current_page: nil, content: nil, current: false, label:))
    end

    def next(
      text = UNSET,
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
      text = default_text(text, I18n.t("nitro_kit.pagination.next"), content)
      validate_boolean!(:disabled, disabled)
      append_navigation_item(
        :next,
        text:,
        href:,
        icon_end: icon,
        disabled: disabled || missing_href?(href),
        default_label: I18n.t("nitro_kit.pagination.next_page"),
        id:,
        html:,
        aria:,
        data:,
        desperately_need_a_class:,
        &content
      )
    end

    private

    def append_pagy_items
      previous = @pagy.previous
      prev(href: previous && pagy_page_url(previous))

      pagy_series.each do |item|
        case item
        when Integer
          page(item, href: pagy_page_url(item))
        when String
          page(item, current: true)
        when :gap
          ellipsis
        else
          raise ArgumentError, "Pagination received an unknown Pagy series item: #{item.inspect}"
        end
      end

      following = @pagy.next
      self.next(href: following && pagy_page_url(following))
    end

    # Pagy's `series` is protected; `data_hash` is its public accessor for it.
    def pagy_series
      @pagy.data_hash(data_keys: [ :series ]).fetch(:series)
    end

    def pagy_page_url(page)
      return @page_url.call(page) if @page_url

      @pagy.page_url(page)
    end

    def validate_pagy!(pagy, page_url:)
      if page_url && !page_url.respond_to?(:call)
        raise ArgumentError, "Pagination page_url must be callable"
      end
      return unless pagy

      required = %i[previous next data_hash]
      required << :page_url unless page_url
      missing = required.reject { |method| pagy.respond_to?(method) }
      return if missing.empty?

      raise ArgumentError,
        "Pagination pagy must respond to #{missing.join(", ")}"
    end

    def append_navigation_item(
      kind,
      text:,
      href:,
      icon: nil,
      icon_end: nil,
      disabled:,
      default_label:,
      id:,
      html:,
      aria:,
      data:,
      desperately_need_a_class:,
      &content
    )
      validate_content!(text, content, icon || icon_end, name: "#{kind} label or icon")
      validate_aria!(aria, reserved: %w[disabled current])
      item_aria = accessible_item_aria(aria, text:, content:, default_label:)

      button = pagination_button(
        text,
        href:,
        icon:,
        icon_end:,
        disabled:,
        id:,
        html:,
        aria: item_aria,
        data:,
        desperately_need_a_class:
      )

      append(Item.new(kind:, button:, current_page: nil, content:, current: false, label: nil))
    end

    def pagination_button(
      text,
      href:,
      disabled:,
      icon: nil,
      icon_end: nil,
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
        icon_end:,
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
        elsif item.current_page
          render_current_page(item)
        else
          render_in_slot(item.button, item.kind, &item.content)
        end
      end
    end

    def render_current_page(item)
      span(**item.current_page.attributes) do
        span(**slot_attributes(:current_label)) do
          item.content ? render(item.content) : plain(item.current_page.text.to_s)
        end
      end
    end

    def render_ellipsis(item)
      span(**slot_attributes(:ellipsis, aria: { hidden: true })) { "…" }
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

    # An omitted label falls back to the default text, unless a content block
    # supplies its own label.
    def default_text(text, default, content)
      return text unless text.equal?(UNSET)

      content ? nil : default
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
