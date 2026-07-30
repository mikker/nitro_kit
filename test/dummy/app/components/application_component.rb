class ApplicationComponent < Phlex::HTML
  include NitroKit

  private

  def merge_attributes(defaults = {}, html: {}, data: {}, aria: {})
    defaults = canonical_attributes(defaults, "defaults")
    html = canonical_attributes(html, "HTML")
    validate_html_boundaries!(html)

    default_data = canonical_attributes(defaults.delete(:data) || {}, "default data", prefix: "data")
    default_aria = canonical_attributes(defaults.delete(:aria) || {}, "default ARIA", prefix: "aria")
    data = canonical_attributes(data, "data", prefix: "data")
    aria = canonical_attributes(aria, "ARIA", prefix: "aria")
    classes = merged_classes(defaults.delete(:class), html.delete(:class))

    defaults.merge(html).tap do |attributes|
      attributes[:class] = classes if classes
      attributes[:data] = default_data.merge(data) if default_data.any? || data.any?
      attributes[:aria] = default_aria.merge(aria) if default_aria.any? || aria.any?
    end
  end

  def canonical_attributes(value, name, prefix: nil)
    raise ArgumentError, "#{name} must be a Hash" unless value.is_a?(Hash)

    value.each_with_object({}) do |(key, item), normalized|
      unless key.is_a?(String) || key.is_a?(Symbol)
        raise ArgumentError, "#{name} attribute keys must be Strings or Symbols"
      end

      key = key.to_s.downcase.tr("_", "-").to_sym
      emitted_name = [ prefix, key ].compact.join("-")
      raise ArgumentError, "Duplicate #{name} attribute #{emitted_name}" if normalized.key?(key)

      normalized[key] = item
    end
  end

  def validate_html_boundaries!(html)
    html.each_key do |key|
      boundary = %w[data aria].find do |name|
        key == name.to_sym || key.to_s.start_with?("#{name}-")
      end
      next unless boundary

      raise ArgumentError, "Pass #{key} through #{boundary}:, not html:"
    end
  end

  def merged_classes(*values)
    tokens = values.compact.flat_map do |value|
      raise ArgumentError, "class values must be Strings" unless value.is_a?(String)

      value.split
    end
    tokens = tokens.reverse.uniq.reverse
    tokens.join(" ") if tokens.any?
  end
end
