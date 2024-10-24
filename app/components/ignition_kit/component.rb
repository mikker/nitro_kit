module IgnitionKit
  class Component < Phlex::HTML
    attr_reader :attrs, :class_list

    def merge(*)
      self.class.merge(*)
    end

    def self.merge(*args)
      @merger ||= TailwindMerge::Merger.new
      @merger.merge(*args)
    end
  end
end
