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
      multiple accept min max step minlength maxlength rows cols wrap pattern inputmode
    ].freeze
    UNSUPPORTED_HELPERS = {
      label: "form.field(:attribute, label: \"...\")",
      collection_select: "form.field(:attribute, as: :select, options: ...)",
      grouped_collection_select: "form.field(:attribute, as: :select, option_tags: ...)",
      collection_radio_buttons: "form.field(:attribute, as: :radio_group, options: ...)",
      collection_check_boxes: "NitroKit::CheckboxGroup through form.field(:attribute, as: :checkbox)",
      date_select: "form.field(:attribute, as: :date)",
      time_zone_select: "form.field(:attribute, as: :select, options: ...)"
    }.freeze

    UNSUPPORTED_HELPERS.each do |method_name, replacement|
      define_method(method_name) do |*_arguments, **_options, &_block|
        raise ArgumentError,
          "NitroKit::FormBuilder does not implement #{method_name}; use #{replacement}"
      end
    end

    def fieldset(**attributes, &block)
      @template.render(NitroKit::Fieldset.new(**attributes), &block)
    end

    def field(
      field_name,
      as: :string,
      label: nil,
      errors: nil,
      html: {},
      aria: {},
      data: {},
      control_html: {},
      control_aria: {},
      control_data: {},
      wrapper_html: {},
      wrapper_aria: {},
      wrapper_data: {},
      **attributes,
      &block
    )
      as = validate_as!(as)
      errors ||= errors_for(field_name)
      control_html = merge_control_boundary(:html, control_html, html)
      control_aria = merge_control_boundary(:aria, control_aria, aria)
      control_data = merge_control_boundary(:data, control_data, data)

      if as == :rich_text
        return rich_text_field(
          field_name,
          label:,
          errors:,
          control_html:,
          control_aria:,
          control_data:,
          html: wrapper_html,
          aria: wrapper_aria,
          data: wrapper_data,
          **attributes
        )
      end
      self.multipart = true if as == :file

      @template.render(
        NitroKit::Field.new(
          self,
          field_name,
          as:,
          label:,
          errors:,
          html: wrapper_html,
          aria: wrapper_aria,
          data: wrapper_data,
          control_html:,
          control_aria:,
          control_data:,
          **attributes
        ),
        &block
      )
    end

    def group(**attributes, &block)
      @template.render(NitroKit::FieldGroup.new(**attributes), &block)
    end

    def dropzone(
      field_name,
      id: nil,
      label: I18n.t("nitro_kit.dropzone.label"),
      description: nil,
      presentation: :minimal,
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
          label:,
          description:,
          presentation:,
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
      options = options.symbolize_keys.merge(attributes)
      value = I18n.t("nitro_kit.form.submit") if value.nil? && !block
      options[:name] = "commit" unless options.key?(:name)
      options[:value] = value if value && options[:name] == "commit" && !options.key?(:value)

      @template.render(Button.new(value, variant: :primary, type: :submit, **options), &block)
    end

    def button(value = nil, options = {}, **attributes, &block)
      options = options.symbolize_keys.merge(attributes)
      value = I18n.t("nitro_kit.form.submit") if value.nil? && !block
      options[:type] = :submit unless options.key?(:type)

      @template.render(Button.new(value, **options), &block)
    end

    def select(field_name, choices = nil, options = {}, html_options = {}, &block)
      options = options.symbolize_keys
      option_tags = @template.capture(&block) if block
      option_tags ||= choices if choices.is_a?(ActiveSupport::SafeBuffer)
      prompt = options[:prompt] == true ? I18n.t("helpers.select.prompt", default: "Please select") : options[:prompt]
      selected = options.key?(:selected) ? { value: options[:selected] } : {}

      field(
        field_name,
        as: :select,
        options: option_tags ? nil : choices,
        option_tags:,
        include_blank: options[:include_blank],
        prompt:,
        label: false,
        **selected,
        **normalize_control_options(html_options)
      )
    end

    private

    def rich_text_field(field_name, label:, errors:, description: nil, control_html: {}, **attributes)
      editor_options = {
        id: field_id(field_name),
        placeholder: attributes[:placeholder],
        required: attributes[:required]
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
      has_name ? aria : aria.merge(label: default_label_for(field_name))
    end

    def default_label_for(field_name)
      if object && object.class.respond_to?(:human_attribute_name)
        object.class.human_attribute_name(field_name)
      else
        field_name.to_s.humanize
      end
    end

    def validate_as!(as)
      normalized = as.to_s.tr("-", "_").to_sym
      return normalized if NitroKit::Field::TYPES.include?(normalized)

      raise ArgumentError,
        "Unknown as: #{as.inspect}; expected one of: #{NitroKit::Field::TYPES.map(&:inspect).join(", ")}"
    end

    def merge_control_boundary(name, control, shorthand)
      control = (control || {}).symbolize_keys
      shorthand = (shorthand || {}).symbolize_keys
      duplicates = control.keys & shorthand.keys
      if duplicates.any?
        raise ArgumentError, "#{duplicates.first} was given through both #{name}: and control_#{name}:"
      end

      control.merge(shorthand)
    end

    def errors_for(field_name)
      return unless object&.respond_to?(:errors) && object.errors.include?(field_name)

      object.errors.full_messages_for(field_name)
    end

    def normalize_control_options(options)
      options = options.symbolize_keys
      normalized = options.extract!(*CONTROL_OPTIONS)
      control_html = merge_control_boundary(:html, options.delete(:control_html), options.delete(:html))
      control_data = merge_control_boundary(:data, options.delete(:control_data), options.delete(:data))
      control_aria = merge_control_boundary(:aria, options.delete(:control_aria), options.delete(:aria))

      normalized.merge(
        control_html: merge_control_boundary(:html, control_html, options),
        control_data:,
        control_aria:
      )
    end

    def value_for(field_name)
      object.public_send(field_name) if object&.respond_to?(field_name)
    end
  end
end
