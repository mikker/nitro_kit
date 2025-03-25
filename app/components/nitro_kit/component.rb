# frozen_string_literal: true

module NitroKit
  class Component < Phlex::HTML
    def initialize(*hashes, **defaults)
      @attrs = merge_attrs(*hashes, **defaults)
    end

    attr_reader :attrs

    private

    # Class-level helper method for builder style components.
    # When called from erb or templates, we need to wrap the return value
    # in capture so we don't write to the output buffer immediately.
    # However when called from other components, we don't.
    def self.builder_method(method_name)
      mod = Module.new
      mod.module_eval(
        <<~RUBY,
          # frozen_string_literal: true

          def #{method_name}(...)
            if caller_locations(1, 1).first.path.end_with?(".rb")
              super
            else
              capture { super }
            end
          end
        RUBY
        __FILE__,
        __LINE__ + 1
      )

      prepend(mod)
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
