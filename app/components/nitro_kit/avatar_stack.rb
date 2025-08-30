# frozen_string_literal: true

module NitroKit
  class AvatarStack < Component
    def initialize(size: :md, **attrs)
      @size = size

      super(attrs)
    end

    attr_reader :size

    def view_template
      div(**mattr(attrs, class: "flex items-center -space-x-3 [&>div]:ring-2 [&>div]:ring-background")) do
        yield
      end
    end

    def avatar(*args, **attrs, &block)
      render(Avatar.new(*args, size:, **attrs, &block))
    end
  end
end
