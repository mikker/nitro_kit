# frozen_string_literal: true

module NitroKit
  module AvatarHelper
    def nk_avatar(src = nil, **attrs, &block)
      render(Avatar.from_template(src, **attrs), &block)
    end

    def nk_avatar_stack(**attrs, &block)
      render(AvatarStack.from_template(**attrs), &block)
    end
  end
end
