# frozen_string_literal: true

module NitroKit
  class FormSection < Component
    Child = Data.define(:component, :content)

    def initialize(
      title: nil,
      description: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title_content = content_from_keyword(:title, title)
      @description_content = content_from_keyword(:description, description)
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

    def view_template
      yield self if block_given?
      require_content!("FormSection", :title, @title_content)
      raise ArgumentError, "FormSection requires exactly one form" unless @form

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          h2(**slot_attributes(:title)) { render_deferred_content(@title_content) }
          if @description_content
            p(**slot_attributes(:description)) { render_deferred_content(@description_content) }
          end
        end
        render_in_slot(@status.component, :status, &@status.content) if @status
        div(**slot_attributes(:form), &@form)
      end
    end

    def title(text = nil, &block)
      @title_content = declare_content(:title, @title_content, text, &block)
      nil
    end

    def description(text = nil, &block)
      @description_content = declare_content(:description, @description_content, text, &block)
      nil
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
  end
end
