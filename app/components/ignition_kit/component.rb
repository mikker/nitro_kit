module IgnitionKit
  class Component < Phlex::HTML
    attr_reader :attrs, :class_list

    def initialize(**attrs)
      @class_list = attrs.delete(:class)
      @attrs = attrs.symbolize_keys
    end

    attr_reader :class_list, :attrs

    def merge(*)
      self.class.merge(*)
    end

    def self.merge(*args)
      @merger ||= TailwindMerge::Merger.new
      @merger.merge(*args)
    end
  end
end
