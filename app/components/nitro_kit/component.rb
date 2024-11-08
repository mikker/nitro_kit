module NitroKit
  Merger = TailwindMerge::Merger.new

  class Component < Phlex::HTML
    attr_reader :attrs

    def initialize(**attrs)
      @attrs = attrs.symbolize_keys
    end

    attr_reader :attrs

    def merge(*args)
      self.class.merge(*args)
    end

    def self.merge(*args)
      Merger.merge(args)
    end

    def data_merge(*hashes)
      hashes.compact.reverse.reduce({}) do |acc, hash|
        acc.deep_merge(hash) do |_key, old_val, new_val|
          [old_val, new_val].compact.join(" ")
        end
      end
    end
  end
end
