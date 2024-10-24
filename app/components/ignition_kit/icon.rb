module IgnitionKit
  class Icon < Component
    include Phlex::Rails::Helpers::ContentTag
    include LucideRails::RailsHelper

    def initialize(name:, **attrs)
      @name = name
      @attrs = attrs
    end

    attr_reader :name

    def view_template
      lucide_icon(name, **attrs)
    end
  end
end
