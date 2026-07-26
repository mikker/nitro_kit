# frozen_string_literal: true

module NitroKit
  class PageHeader < Component
    Child = Data.define(:component, :content)
    TITLE_LEVELS = (1..6).freeze

    def initialize(
      title: nil,
      eyebrow: nil,
      description: nil,
      level: 1,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title_content = content_from_keyword(:title, title)
      @eyebrow_content = content_from_keyword(:eyebrow, eyebrow)
      @description_content = content_from_keyword(:description, description)
      @level = validate_choice!(:level, level, TITLE_LEVELS)
      @actions = nil

      super(
        component: :page_header,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :level

    def view_template
      yield self if block_given?
      require_content!("PageHeader", :title, @title_content)

      header(**root_attributes) do
        p(**slot_attributes(:eyebrow)) { render_deferred_content(@eyebrow_content) } if @eyebrow_content
        public_send(:"h#{level}", **slot_attributes(:title)) { render_deferred_content(@title_content) }
        if @description_content
          p(**slot_attributes(:description)) { render_deferred_content(@description_content) }
        end
        render_in_slot(@actions.component, :actions, &@actions.content) if @actions
      end
    end

    def eyebrow(text = nil, &block)
      @eyebrow_content = declare_content(:eyebrow, @eyebrow_content, text, &block)
      nil
    end

    def title(text = nil, &block)
      @title_content = declare_content(:title, @title_content, text, &block)
      nil
    end

    def description(text = nil, &block)
      @description_content = declare_content(:description, @description_content, text, &block)
      nil
    end

    def actions(component, &content)
      unless component.is_a?(NitroKit::ButtonGroup)
        raise ArgumentError, "PageHeader actions must be a NitroKit::ButtonGroup"
      end
      raise ArgumentError, "PageHeader accepts at most one actions group" if @actions

      @actions = Child.new(component:, content:)
      nil
    end
  end
end
