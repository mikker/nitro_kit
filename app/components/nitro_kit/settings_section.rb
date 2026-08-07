# frozen_string_literal: true

module NitroKit
  class SettingsSection < Component
    Child = Data.define(:component, :content)
    TITLE_LEVELS = (1..6).freeze

    def initialize(
      title: nil,
      description: nil,
      level: 2,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @title_level = validate_choice!(:level, level, TITLE_LEVELS)
      @title_content = content_from_keyword(:title, title)
      @description_content = content_from_keyword(:description, description)
      @status = nil
      @form = nil
      @title_id = "#{id || "nk-settings-section-#{SecureRandom.hex(4)}"}-title"

      super(
        component: :settings_section,
        attributes: { id:, aria: { labelledby: @title_id } }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      yield self if block_given?
      require_content!("SettingsSection", :title, @title_content)
      raise ArgumentError, "SettingsSection requires exactly one form" unless @form

      section(**root_attributes) do
        header(**slot_attributes(:header)) do
          public_send(
            :"h#{@title_level}",
            **slot_attributes(:title, attributes: { id: @title_id })
          ) do
            render_deferred_content(@title_content)
          end
          if @description_content
            p(**slot_attributes(:description)) { render_deferred_content(@description_content) }
          end
        end
        render_in_slot(@status.component, :status, &@status.content) if @status
        div(**slot_attributes(:form), &@form)
      end
    end

    def title(text = nil, level: nil, &block)
      @title_level = validate_choice!(:level, level, TITLE_LEVELS) if level
      @title_content = declare_content(:title, @title_content, text, &block)
      nil
    end

    def description(text = nil, &block)
      @description_content = declare_content(:description, @description_content, text, &block)
      nil
    end

    def status(component, &content)
      unless component.is_a?(NitroKit::Alert)
        raise ArgumentError, "SettingsSection status must be a NitroKit::Alert"
      end
      raise ArgumentError, "SettingsSection accepts at most one status" if @status

      @status = Child.new(component:, content:)
      nil
    end

    def form(&content)
      raise ArgumentError, "SettingsSection form requires a block" unless content
      raise ArgumentError, "SettingsSection accepts exactly one form" if @form

      @form = content
      nil
    end
  end
end
