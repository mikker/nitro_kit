# frozen_string_literal: true

module NitroKit
  class DetailsTable < Component
    include Phlex::Rails::Helpers::Routes

    UNSET = Object.new.freeze
    Field = Data.define(:attribute, :label, :value, :content)

    def initialize(
      record,
      route_base: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @record = record
      @route_base = route_base
      @fields = []
      @table = Table.new

      super(
        component: :details_table,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :record, :route_base

    def view_template
      yield self if block_given?
      raise ArgumentError, "DetailsTable requires at least one field" if @fields.empty?

      div(**root_attributes) do
        render_in_slot(@table, :table) do
          @table.tbody do
            @fields.each { |field| render_field(field) }
          end
        end
      end
    end

    def fields(*attributes)
      raise ArgumentError, "DetailsTable fields requires at least one attribute" if attributes.empty?

      attributes.each { |attribute| field(attribute) }
      nil
    end

    def field(attribute, label: nil, value: UNSET, &content)
      attribute = validate_attribute!(attribute)
      label = label.nil? ? attribute.to_s.humanize : validate_label!(label)
      resolved_value = value.equal?(UNSET) ? resolve_attribute(attribute) : value

      @fields << Field.new(attribute:, label:, value: resolved_value, content:)
      nil
    end

    private

    def render_field(field)
      @table.tr do
        @table.th(field.label, scope: :row)
        @table.td do
          if field.content
            field.content.call(field.value)
          else
            render_value(field.value)
          end
        end
      end
    end

    def render_value(value)
      case value
      when nil
        em(**slot_attributes(:empty)) { "Not provided" }
      when true, false
        span(**slot_attributes(:boolean)) { value ? "Yes" : "No" }
      when Date, Time, ActiveSupport::TimeWithZone
        time(**slot_attributes(:time, attributes: { datetime: value.iso8601 })) do
          plain(I18n.localize(value, format: :long).to_s)
        end
      when Numeric
        span(**slot_attributes(:number)) { plain(value.to_s) }
      when Symbol
        plain(value.to_s.humanize)
      when String
        render_string(value)
      else
        render_special_value(value)
      end
    end

    def render_string(value)
      if value.start_with?("https://", "http://")
        a(
          **slot_attributes(
            :link,
            attributes: { href: value, target: "_blank", rel: "noopener noreferrer" }
          )
        ) { plain(value) }
      else
        plain(value)
      end
    end

    def render_special_value(value)
      if active_storage_attachment?(value)
        render_attachment(value)
      elsif active_record?(value)
        render_record(value)
      elsif collection?(value)
        render_collection(value)
      else
        plain(value.to_s)
      end
    end

    def render_attachment(attachment)
      return render_value(nil) unless attachment.attached?

      if attachment.blob.image? && attachment.blob.variable?
        render_in_slot(
          ProgressiveImage.new(
            attachment:,
            alt: attachment.filename.to_s,
            size: :sm
          ),
          :attachment
        )
      else
        code(**slot_attributes(:file)) { plain(attachment.filename.to_s) }
      end
    end

    def render_record(value)
      route = route_base ? [ *Array(route_base), value ] : value
      a(**slot_attributes(:record, attributes: { href: url_for(route) })) do
        plain(record_name(value))
      end
    end

    def render_collection(values)
      span(**slot_attributes(:list)) do
        values.each_with_index do |value, index|
          plain(", ") if index.positive?
          span(**slot_attributes(:list_item)) { render_value(value) }
        end
      end
    end

    def record_name(value)
      label = value.to_label if value.respond_to?(:to_label)
      label = value.name if label.blank? && value.respond_to?(:name)
      label.presence || "#{value.class.model_name.human} ##{value.id}"
    end

    def active_storage_attachment?(value)
      defined?(ActiveStorage::Attached::One) && value.is_a?(ActiveStorage::Attached::One)
    end

    def active_record?(value)
      defined?(ActiveRecord::Base) && value.is_a?(ActiveRecord::Base)
    end

    def collection?(value)
      value.is_a?(Array) || (
        defined?(ActiveRecord::Associations::CollectionProxy) &&
          value.is_a?(ActiveRecord::Associations::CollectionProxy)
      )
    end

    def resolve_attribute(attribute)
      return record.public_send(attribute) if record.respond_to?(attribute)

      raise ArgumentError, "#{record.class} does not expose #{attribute.inspect}"
    end

    def validate_attribute!(attribute)
      return attribute if attribute.is_a?(Symbol)
      return attribute if attribute.is_a?(String) && !attribute.strip.empty?

      raise ArgumentError, "DetailsTable field attribute must be a Symbol or non-blank String"
    end

    def validate_label!(label)
      return label if label.is_a?(String) && !label.strip.empty?

      raise ArgumentError, "DetailsTable field label must be a non-blank String"
    end
  end
end
