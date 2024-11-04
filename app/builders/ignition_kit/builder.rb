module IgnitionKit
  class Builder
    def initialize(template)
      @template = template
      yield(self)
    end

    attr_reader :template
  end
end
