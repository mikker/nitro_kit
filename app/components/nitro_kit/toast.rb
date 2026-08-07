# frozen_string_literal: true

module NitroKit
  class Toast < Component
    DEFAULT_ID = "nk-toast"

    ItemDeclaration = ::Data.define(:component, :content)
    private_constant :ItemDeclaration

    class Item < Component
      VARIANTS = %i[default info success warning error].freeze
      ASSERTIVE_VARIANTS = %i[error].freeze

      def initialize(
        title: nil,
        description: nil,
        variant: :default,
        dismissible: true,
        id: nil,
        html: {},
        aria: {},
        data: {},
        desperately_need_a_class: nil
      )
        @title = optional_text(:title, title)
        @description = optional_text(:description, description)
        @variant = validate_choice!(:variant, variant, VARIANTS)
        @dismissible = validate_boolean!(:dismissible, dismissible)

        super(
          component: :toast_item,
          attributes: {
            id:,
            role: ASSERTIVE_VARIANTS.include?(@variant) ? "alert" : "status",
            aria: { atomic: true },
            data: {
              state: "open",
              turbo_temporary: true,
              nk__toast_target: "item",
              nk__toast_permanent: dismissible ? nil : "true",
              action: [
                "pointerenter->nk--toast#pause",
                "pointerleave->nk--toast#resume",
                "focusin->nk--toast#pause",
                "focusout->nk--toast#resume",
                "transitionend->nk--toast#remove"
              ].join(" ")
            }
          },
          html:,
          aria:,
          data:,
          variant:,
          desperately_need_a_class:
        )
      end

      attr_reader :title, :description, :variant, :dismissible

      def view_template(&block)
        if title.nil? && description.nil? && !block
          raise ArgumentError, "Toast item requires a title, description, or block"
        end

        li(**root_attributes) do
          div(**slot_attributes(:content)) do
            p(**slot_attributes(:title)) { plain(title) } if title
            div(**slot_attributes(:description)) do
              block ? yield : plain(description.to_s)
            end if description || block
          end

          dismiss_button if dismissible
        end
      end

      private

      def dismiss_button
        render_in_slot(
          Button.new(
            icon: :x,
            variant: :ghost,
            size: :sm,
            aria: { label: I18n.t("nitro_kit.toast.dismiss") },
            data: { action: "click->nk--toast#dismiss" }
          ),
          :dismiss
        )
      end

      def optional_text(name, value)
        return if value.nil?
        return value if value.is_a?(String) && value.present?

        raise ArgumentError, "Toast item #{name} must be nil or a non-blank String"
      end
    end

    class FlashMessages < Toast
      VARIANT_BY_SEVERITY = {
        "alert" => :error,
        "error" => :error,
        "warning" => :warning,
        "success" => :success,
        "info" => :info,
        "notice" => :default
      }.freeze

      def initialize(
        flash:,
        duration: 5_000,
        label: I18n.t("nitro_kit.toast.label"),
        id: DEFAULT_ID,
        html: {},
        aria: {},
        data: {},
        desperately_need_a_class: nil
      )
        unless flash.respond_to?(:each)
          raise ArgumentError, "Toast::FlashMessages flash must be enumerable"
        end

        @flash = flash

        super(
          duration:,
          label:,
          id:,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      end

      attr_reader :flash

      def view_template
        super do |toast|
          flash.each do |severity, message|
            toast.item(
              description: message.to_s,
              variant: VARIANT_BY_SEVERITY.fetch(severity.to_s, :default)
            )
          end
        end
      end
    end

    def initialize(
      duration: 5_000,
      label: I18n.t("nitro_kit.toast.label"),
      id: DEFAULT_ID,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      unless duration.is_a?(Integer) && duration.positive?
        raise ArgumentError, "Toast duration must be a positive Integer"
      end
      unless label.is_a?(String) && label.present?
        raise ArgumentError, "Toast label must be a non-blank String"
      end
      unless id.is_a?(String) && id.present? && !id.match?(/\s/)
        raise ArgumentError, "Toast id: must be a non-blank String without whitespace"
      end

      @duration = duration
      @id = id
      @items = []

      super(
        component: :toast,
        attributes: {
          id:,
          role: "region",
          aria: { label: },
          data: {
            controller: "nk--toast",
            action: "turbo:before-cache@document->nk--toast#teardown",
            nk__toast_duration_value: duration
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :duration, :id

    def list_id
      "#{id}-list"
    end

    def view_template(&block)
      collect_items(&block)

      section(**root_attributes) do
        ol(**slot_attributes(:list, attributes: { id: list_id })) do
          @items.each do |entry|
            render_in_slot(entry.component, :item, &entry.content)
          end
        end
      end
    end

    def item(
      title: nil,
      description: nil,
      variant: :default,
      dismissible: true,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      ensure_collecting!
      component = Item.new(
        title:,
        description:,
        variant:,
        dismissible:,
        id:,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
      @items << ItemDeclaration.new(component:, content:)
      nil
    end

    private

    def collect_items
      return unless block_given?

      @collecting = true
      yield(self)
    ensure
      @collecting = false
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "Toast items must be declared inside the render block"
    end
  end
end
