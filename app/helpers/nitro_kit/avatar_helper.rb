# frozen_string_literal: true

module NitroKit
  module AvatarHelper
    def nk_avatar(src = nil, **attrs, &block)
      render(Avatar.new(src, **attrs), &block)
    end

    def nk_avatar_stack(**attrs, &block)
      render(AvatarStack.new(**attrs), &block)
    end
  end
end
