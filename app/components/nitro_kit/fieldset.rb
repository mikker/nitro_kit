# frozen_string_literal: true

module NitroKit
  class Fieldset < Component
    alias :html_legend :legend

    def initialize(
      legend: nil,
      description: nil,
      disabled: false,
      name: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @legend_content = content_from_keyword(:legend, legend)
      @description_content = content_from_keyword(:description, description)
      disabled = validate_boolean!(:disabled, disabled)

      super(
        component: :fieldset,
        attributes: { disabled:, name: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template(&block)
      raise ArgumentError, "Fieldset requires a block" unless block

      fields = capture(self) { |fieldset| yield fieldset }
      require_content!("Fieldset", :legend, @legend_content)

      fieldset(**root_attributes) do
        html_legend(**slot_attributes(:legend)) { render_deferred_content(@legend_content) }
        if @description_content
          p(**slot_attributes(:description)) { render_deferred_content(@description_content) }
        end
        div(**slot_attributes(:fields)) { raw(safe(fields)) }
      end
    end

    def legend(text = nil, &block)
      @legend_content = declare_content(:legend, @legend_content, text, &block)
      nil
    end

    def description(text = nil, &block)
      @description_content = declare_content(:description, @description_content, text, &block)
      nil
    end
  end
end
