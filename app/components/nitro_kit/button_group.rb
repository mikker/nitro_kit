# frozen_string_literal: true

module NitroKit
  class ButtonGroup < Component
    Entry = Data.define(:button, :content)

    def initialize(
      buttons: [],
      label: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      raise ArgumentError, "buttons must be an Array" unless buttons.is_a?(Array)
      unless label.nil? || (label.is_a?(String) && !label.strip.empty?)
        raise ArgumentError, "label must be a non-blank String or nil"
      end
      raise ArgumentError, "aria must be a Hash" unless aria.is_a?(Hash)

      @entries = []
      buttons.each { |button| add(button) }

      super(
        component: :button_group,
        attributes: { id:, role: "group" },
        html:,
        aria: label ? aria.merge(label:) : aria,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      yield self if block_given?
      raise ArgumentError, "ButtonGroup requires at least one Button" if @entries.empty?

      div(**root_attributes) do
        @entries.each do |entry|
          render_in_slot(entry.button, :button, &entry.content)
        end
      end
    end

    def add(button, &content)
      unless button.is_a?(NitroKit::Button)
        raise ArgumentError, "ButtonGroup accepts only NitroKit::Button children"
      end
      if @entries.any? { |entry| entry.button.equal?(button) }
        raise ArgumentError, "ButtonGroup cannot contain the same Button twice"
      end

      @entries << Entry.new(button:, content:)
      nil
    end

    def button(
      text = nil,
      href: nil,
      variant: :default,
      size: :md,
      icon: nil,
      icon_right: nil,
      id: nil,
      type: :button,
      name: nil,
      value: nil,
      form: nil,
      target: nil,
      rel: nil,
      download: nil,
      disabled: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      add(
        Button.new(
          text,
          href:,
          variant:,
          size:,
          icon:,
          icon_right:,
          id:,
          type:,
          name:,
          value:,
          form:,
          target:,
          rel:,
          download:,
          disabled:,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        ),
        &content
      )
    end
  end
end
