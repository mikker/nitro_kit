# frozen_string_literal: true

module NitroKit
  class FormSection < Component
    Child = Data.define(:component, :content)

    def initialize(
      title:,
      description: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title = validate_text!(:title, title)
      @description = validate_optional_text!(:description, description)
      @status = nil
      @form = nil

      super(
        component: :form_section,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :title, :description

    def view_template
      yield self if block_given?
      raise ArgumentError, "FormSection requires exactly one form" unless @form

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          h2(**slot_attributes(:title)) { plain(title) }
          p(**slot_attributes(:description)) { plain(description) } if description
        end
        render_in_slot(@status.component, :status, &@status.content) if @status
        div(**slot_attributes(:form), &@form)
      end
    end

    def status(component, &content)
      unless component.is_a?(NitroKit::Alert)
        raise ArgumentError, "FormSection status must be a NitroKit::Alert"
      end
      raise ArgumentError, "FormSection accepts at most one status" if @status

      @status = Child.new(component:, content:)
      nil
    end

    def form(&content)
      raise ArgumentError, "FormSection form requires a block" unless content
      raise ArgumentError, "FormSection accepts exactly one form" if @form

      @form = content
      nil
    end

    private

    def validate_text!(name, value)
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def validate_optional_text!(name, value)
      return if value.nil?

      validate_text!(name, value)
    end
  end
end
