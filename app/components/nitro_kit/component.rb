# frozen_string_literal: true

module NitroKit
  class Component < Phlex::HTML
    def initialize(*hashes)
      @attrs = merge_attrs(*hashes)
    end

    attr_reader :attrs

    private

    # Merge attributes with some special cases for matching keys
    def merge_attrs(*hashes, **default)
      default.merge(*hashes) do |key, old_value, new_value|
        case key
        when :class
          # Use TailwindMerge to merge class names
          next merge_class(old_value, new_value)
        when :data
          # Merge data hashes with some special cases for Stimulus
          next merge_data(old_value, new_value)
        end

        # If both values are hashes, merge them
        if old_value.is_a?(Hash) && new_value.is_a?(Hash)
          next old_value.merge(new_value)
        end

        # If nothing of the above, override with new value
        new_value
      end
    end

    alias :mattr :merge_attrs

    def merge_class(*args)
      @@merger ||= TailwindMerge::Merger.new
      @@merger.merge(args)
    end

    def merge_data(*hashes)
      hashes.compact.reduce({}) do |acc, hash|
        acc.deep_merge(hash) do |key, old_val, new_val|
          case key
          # Concat Stimulus actions
          when :action
            [new_val, old_val].compact.join(" ")
          when :controller
            [old_val, new_val].compact.join(" ")
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
