module IgnitionKit
  class Component < Phlex::HTML
    attr_reader :attrs, :class_list

    def initialize(**attrs)
      @class_list = attrs.delete(:class)
      @attrs = attrs.symbolize_keys
    end

    attr_reader :class_list, :attrs

    def merge(*args)
      self.class.merge(*args)
    end

    def self.merge(*args)
      @merger ||= TailwindMerge::Merger.new
      @merger.merge(*args)
    end

    def data_merge(data = {}, new_data = {})
      data.deep_merge(new_data) do |_key, old_val, new_val|
        # Put new value first so overrides can stopPropagation to old value
        [new_val, old_val].compact.join(" ")
      end
    end
  end
end
