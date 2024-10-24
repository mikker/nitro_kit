module IgnitionKit
  class Field < Component
    FIELD_BASE = [
      "flex flex-col gap-2 align-start",
      "[&:has([data-slot='error'])_[data-slot='control']]:border-destructive"
    ].freeze
    LABEL_BASE = "text-sm font-medium"
    DESCRIPTION_BASE = "text-sm text-muted-foreground"
    ERROR_BASE = "text-sm text-destructive"
    INPUT_BASE = [
      "rounded-md border bg-background border-border text-base px-3 py-2",
      "focus:outline-none focus:ring-2 focus:ring-primary",
      ""
    ].freeze

    def initialize(attribute, as: :string, label: nil, description: nil, errors: nil, **attrs)
      @attribute = attribute
      @as = as
      @label_text = label
      @description_text = description
      @errors = errors || []
      @attrs = attrs
    end

    attr_reader :attribute, :as, :label_text, :description_text, :errors, :attrs

    def view_template(&block)
      div(**attrs, class: FIELD_BASE) do
        label(**attrs, data: {slot: "label"}, class: LABEL_BASE) { label_text }
        input(**attrs, data: {slot: "control"}, class: INPUT_BASE)
        errors.each do |msg|
          div(**attrs, data: {slot: "error"}, class: ERROR_BASE) { msg }
        end
      end
    end
  end
end
