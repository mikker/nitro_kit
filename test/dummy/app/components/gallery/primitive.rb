module Gallery
  class Primitive < Phlex::HTML
    SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    private

    def normalize_slug(value)
      slug = value.to_s.tr("_", "-")

      return slug if slug.match?(SLUG_PATTERN)

      raise ArgumentError, "#{self.class.name} slug must contain only lowercase letters, numbers, and hyphens"
    end

    def validate_choice!(name, value, choices)
      normalized = value.respond_to?(:to_sym) ? value.to_sym : value

      return normalized if choices.include?(normalized)

      accepted = choices.map(&:inspect).join(", ")
      raise ArgumentError, "Unknown #{name} #{value.inspect} for #{self.class.name}; expected #{accepted}"
    end

    def validate_boolean!(name, value)
      return value if value == true || value == false

      raise ArgumentError, "#{self.class.name} #{name} must be true or false"
    end

    def validate_text!(name, value, optional: false)
      return if optional && value.nil?
      return value if value.is_a?(String) && value.present?

      requirement = optional ? "nil or a non-blank String" : "a non-blank String"
      raise ArgumentError, "#{self.class.name} #{name} must be #{requirement}"
    end

    def data_value(value)
      value.to_s.tr("_", "-")
    end
  end
end
