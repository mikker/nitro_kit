# frozen_string_literal: true

module NitroKit
  class FormBuilder < ActionView::Helpers::FormBuilder
    FIELD_TYPES = {
      color_field: :color,
      date_field: :date,
      datetime_field: :datetime_local,
      datetime_local_field: :datetime_local,
      email_field: :email,
      file_field: :file,
      hidden_field: :hidden,
      month_field: :month,
      number_field: :number,
      password_field: :password,
      phone_field: :tel,
      range_field: :range,
      search_field: :search,
      telephone_field: :tel,
      text_area: :textarea,
      text_field: :text,
      time_field: :time,
      url_field: :url,
      week_field: :week
    }.freeze
    CONTROL_OPTIONS = %i[
      id name value placeholder disabled readonly required autocomplete checked
      multiple accept min max step pattern inputmode
    ].freeze

    def fieldset(**attributes, &block)
      @template.render(NitroKit::Fieldset.new(**attributes), &block)
    end

    def field(field_name, label: nil, errors: nil, **attributes, &block)
      label = field_name.to_s.humanize if label.nil?
      errors ||= errors_for(field_name)
      return rich_text_field(field_name, label:, errors:, **attributes) if attributes[:as].to_s.tr("-", "_") == "rich_text"
      self.multipart = true if attributes[:as].to_s.tr("-", "_") == "file"

      @template.render(
        NitroKit::Field.new(self, field_name, label:, errors:, **attributes),
        &block
      )
    end

    def group(**attributes, &block)
      @template.render(NitroKit::FieldGroup.new(**attributes), &block)
    end

    def dropzone(
      field_name,
      id: nil,
      title: "Upload files",
      description: nil,
      direct_upload: true,
      multiple: false,
      accept: nil,
      max_files: 1,
      max_bytes: nil,
      disabled: false,
      required: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      self.multipart = true

      @template.render(
        Dropzone.new(
          id: id || field_id(field_name),
          name: self.field_name(field_name, multiple:),
          title:,
          description:,
          direct_upload:,
          multiple:,
          accept:,
          max_files:,
          max_bytes:,
          disabled:,
          required:,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      )
    end

    FIELD_TYPES.each do |method_name, field_type|
      define_method(method_name) do |field_name, options = {}, **attributes|
        self.multipart = true if field_type == :file
        field(
          field_name,
          as: field_type,
          label: false,
          **normalize_control_options(options.merge(attributes))
        )
      end
    end

    def hidden_field(field_name, options = {}, **attributes)
      options = options.merge(attributes).symbolize_keys
      value = options.key?(:value) ? options.delete(:value) : value_for(field_name)
      @emitted_hidden_id = true if field_name.to_sym == :id

      @template.render(
        Input.new(
          type: :hidden,
          id: options.delete(:id) || field_id(field_name),
          name: options.delete(:name) || self.field_name(field_name),
          value:,
          disabled: options.delete(:disabled) { false },
          autocomplete: options.delete(:autocomplete),
          data: options.delete(:data) || {},
          aria: options.delete(:aria) || {},
          html: options
        )
      )
    end

    def radio_button(field_name, tag_value = "1", options = {}, **attributes)
      control_options = normalize_control_options(options.merge(attributes))
      control_options[:control_aria] = accessible_control_aria(field_name, control_options[:control_aria])

      field(
        field_name,
        as: :radio_button,
        label: false,
        options: [ [ tag_value, tag_value ] ],
        **control_options
      )
    end

    def check_box(
      field_name,
      options = {},
      checked_value = "1",
      unchecked_value = "0",
      **attributes
    )
      options = options.merge(attributes).symbolize_keys
      include_hidden = options.delete(:include_hidden) { true }
      control_options = normalize_control_options(options)
      control_options[:control_aria] = accessible_control_aria(field_name, control_options[:control_aria])

      field(
        field_name,
        as: :checkbox,
        label: false,
        checked_value:,
        unchecked_value:,
        include_hidden:,
        **control_options
      )
    end

    alias :checkbox :check_box

    def submit(value = nil, options = {}, **attributes, &block)
      value = "Save changes" if value.nil? && !block
      @template.render(Button.new(value, variant: :primary, type: :submit, **options, **attributes), &block)
    end

    def button(value = nil, options = {}, **attributes, &block)
      value = "Save changes" if value.nil? && !block
      @template.render(Button.new(value, **options, **attributes), &block)
    end

    def select(field_name, choices = nil, options = {}, html_options = {}, &block)
      option_tags = @template.capture(&block) if block
      option_tags ||= choices if choices.is_a?(ActiveSupport::SafeBuffer)
      prompt = options[:prompt] == true ? I18n.t("helpers.select.prompt", default: "Please select") : options[:prompt]

      field(
        field_name,
        as: :select,
        options: option_tags ? nil : choices,
        option_tags:,
        include_blank: options[:include_blank],
        prompt:,
        value: options.fetch(:selected, NitroKit::Field::UNSET),
        label: false,
        **normalize_control_options(html_options)
      )
    end

    private

    def rich_text_field(field_name, label:, errors:, description: nil, control_html: {}, **attributes)
      editor_options = {
        id: field_id(field_name),
        placeholder: attributes[:placeholder],
        required: attributes[:required],
        data: attributes[:control_data],
        aria: attributes[:control_aria]
      }.compact.merge(control_html)
      editor = rich_text_area(field_name, editor_options)

      @template.render(
        NitroKit::Field.new(
          self,
          field_name,
          as: :rich_text,
          label:,
          description:,
          errors:,
          rich_text_content: editor,
          **attributes
        )
      )
    end

    def accessible_control_aria(field_name, aria)
      has_name = aria.any? do |key, value|
        %w[label labelledby].include?(key.to_s.tr("_", "-")) && value.to_s.present?
      end
      has_name ? aria : aria.merge(label: field_name.to_s.humanize)
    end

    def errors_for(field_name)
      return unless object&.respond_to?(:errors) && object.errors.include?(field_name)

      object.errors.full_messages_for(field_name)
    end

    def normalize_control_options(options)
      options = options.symbolize_keys
      normalized = options.extract!(*CONTROL_OPTIONS)
      control_html = options.delete(:control_html) || {}
      control_data = options.delete(:control_data) || options.delete(:data) || {}
      control_aria = options.delete(:control_aria) || options.delete(:aria) || {}

      normalized.merge(
        control_html: options.merge(control_html),
        control_data:,
        control_aria:
      )
    end

    def value_for(field_name)
      object.public_send(field_name) if object&.respond_to?(field_name)
    end
  end
end
