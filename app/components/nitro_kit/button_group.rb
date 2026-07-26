# frozen_string_literal: true

module NitroKit
  class ButtonGroup < Component
    Entry = Data.define(:button, :content)

    def initialize(
      buttons: [],
      label: nil,
      variant: nil,
      size: nil,
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

      @variant = variant && validate_choice!(:variant, variant, Button::VARIANTS)
      @size = size && validate_choice!(:size, size, Button::SIZES)
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

    # Declares a member with Button's own signature. Arguments are forwarded
    # verbatim so the group can never restate a stale copy of Button's
    # keywords; unknown keywords raise from Button itself. Group-level
    # variant: and size: fill in only where the member stays silent.
    def button(*arguments, **options, &content)
      add(Button.new(*arguments, **member_defaults.merge(options)), &content)
    end

    private

    def member_defaults
      { variant: @variant, size: @size }.compact
    end
  end
end
