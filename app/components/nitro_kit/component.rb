# frozen_string_literal: true

module NitroKit
  class Component < Phlex::HTML
    def initialize(attrs = {}, **defaults)
      @attrs = merge_attrs(attrs, **defaults)
    end

    attr_reader :attrs

    def self.from_template(*args, **attrs, &block)
      new(*args, **attrs, &block).tap { |instance| instance.instance_variable_set(:@_nk_from_template, true) }
    end

    def builder(&block)
      @_nk_from_template ? capture(&block) : yield
    end

    private

    # Class-level helper method for builder style components.
    # When called from erb or templates, we need to wrap the return value
    # in capture so we don't write to the output buffer immediately.
    # However when called from other components, we don't.
    def self.builder_method(method_name)
      warn(
        "[DEPRECATION] builder_method is deprecated. Please migrate to using the builder(&) pattern. See https://github.com/mikker/nitro_kit/issues/35 for details."
      )

      nil
    end

    # Merge attributes with some special cases for matching keys
    def merge_attrs(*hashes, **defaults)
      defaults
        .merge(*hashes) do |key, old_value, new_value|
          case key
          when :class
            # Use TailwindMerge to merge class names
            merge_class(old_value, new_value)
          when :data
            # Merge data hashes with some special cases for Stimulus
            merge_data(old_value, new_value)
          else
            new_value
          end
        end
    end

    alias :mattr :merge_attrs

    def merge_class(*args)
      @@merger ||= TailwindMerge::Merger.new
      @@merger.merge(args)
    end

    def merge_data(*hashes)
      hashes
        .compact
        .reduce({}) do |acc, hash|
          acc.deep_merge(hash) do |key, old_val, new_val|
            # Concat Stimulus actions
            case key
            when :action, :controller
              [new_val, old_val].compact.join(" ")
            else
              new_val
            end
          end
        end
    end

    def text_or_block(text = nil, &block)
      if text
        plain(text)
      elsif block_given?
        yield
      else
        nil
      end
    end
  end
end
