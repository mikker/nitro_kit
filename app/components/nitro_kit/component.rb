module NitroKit
  class Component < Phlex::HTML
    attr_reader :attrs

    def initialize(**attrs)
      @attrs = attrs.symbolize_keys
    end

    attr_reader :attrs

    private

    def merge(*args)
      @@merger ||= TailwindMerge::Merger.new
      @@merger.merge(args)
    end

    def data_merge(*hashes)
      hashes.compact.reverse.reduce({}) do |acc, hash|
        acc.deep_merge(hash) do |key, old_val, new_val|
          case key
          # Concat Stimulus actions
          when :action then [old_val, new_val].compact.join(" ")
          else new_val
          end
        end
      end
    end
  end
end
