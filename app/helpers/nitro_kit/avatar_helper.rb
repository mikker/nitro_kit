module NitroKit
  module AvatarHelper
    def nk_avatar(src = nil, **attrs, &block)
      render(Avatar.new(src, **attrs), &block)
    end
  end
end
