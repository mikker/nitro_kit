# frozen_string_literal: true

module NitroKit
  class ButtonTo < Component
    include Phlex::Rails::Helpers::FormTag

    METHODS = %i[get post patch put delete].freeze

    def initialize(
      text = nil,
      href:,
      method: :post,
      variant: :default,
      size: :md,
      icon: nil,
      icon_end: nil,
      label: nil,
      id: nil,
      disabled: false,
      loading: false,
      html: {},
      aria: {},
      data: {},
      button_html: {},
      button_aria: {},
      button_data: {},
      desperately_need_a_class: nil
    )
      unless href.is_a?(String) && href.present?
        raise ArgumentError, "ButtonTo href: must be a non-blank String"
      end

      @text = text
      @href = href
      @method = validate_choice!(:method, method.to_s.to_sym, METHODS)
      @button = Button.new(
        text,
        variant:,
        size:,
        icon:,
        icon_end:,
        label:,
        type: :submit,
        disabled:,
        loading:,
        html: button_html,
        aria: button_aria,
        data: button_data
      )

      super(
        component: :button_to,
        attributes: { id: },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :href, :method

    def view_template(&block)
      form_tag(href, method:, **root_attributes) do
        render_in_slot(@button, :button, &block)
      end
    end
  end
end
