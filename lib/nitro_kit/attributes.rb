# frozen_string_literal: true

module NitroKit
  class Attributes
    def self.instance
      @instance ||= new
    end

    def self.merge(...)
      instance.merge_attrs(...)
    end
  end
end
