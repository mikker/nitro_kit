# frozen_string_literal: true

module NitroKit
  class ResponsiveValue
    BREAKPOINTS = {
      "sm" => "40rem",
      "md" => "48rem",
      "lg" => "64rem",
      "xl" => "80rem",
      "2xl" => "96rem"
    }.freeze

    def initialize(property:, value:, allowed:)
      @property = property
      @allowed = allowed.map { |candidate| normalize(candidate) }.freeze
      @values = parse(value).freeze
      freeze
    end

    def to_s
      [ nil, *BREAKPOINTS.keys ].filter_map do |breakpoint|
        value = @values[breakpoint]
        next unless value

        breakpoint ? "#{breakpoint}:#{value}" : value
      end.join(" ")
    end

    private

    def parse(value)
      tokens = tokens_from(value)
      values = {}

      tokens.each do |token|
        breakpoint, candidate = split(token)
        validate_breakpoint!(breakpoint) if breakpoint
        validate_value!(candidate)

        if values.key?(breakpoint)
          label = breakpoint ? "breakpoint #{breakpoint.inspect}" : "base value"
          raise ArgumentError, "Duplicate #{@property} #{label}"
        end

        values[breakpoint] = candidate
      end

      unless values.key?(nil)
        raise ArgumentError, "#{@property} must include an unprefixed base value"
      end

      values
    end

    def tokens_from(value)
      tokens = case value
      when String
        value.split
      when Integer, Symbol
        [ normalize(value) ]
      else
        raise ArgumentError,
          "#{@property} must be an Integer, Symbol, or String; received #{value.inspect}"
      end

      raise ArgumentError, "#{@property} cannot be blank" if tokens.empty?

      tokens
    end

    def normalize(value)
      value.to_s.tr("_", "-")
    end

    def split(token)
      breakpoint, separator, value = token.partition(":")
      separator.empty? ? [ nil, breakpoint ] : [ breakpoint, value ]
    end

    def validate_breakpoint!(breakpoint)
      return if BREAKPOINTS.key?(breakpoint)

      raise ArgumentError,
        "Unknown #{@property} breakpoint #{breakpoint.inspect}; expected one of: #{BREAKPOINTS.keys.join(", ")}"
    end

    def validate_value!(value)
      return if @allowed.include?(value)

      raise ArgumentError,
        "Unknown #{@property} value #{value.inspect}; expected one of: #{@allowed.join(", ")}"
    end
  end
end
