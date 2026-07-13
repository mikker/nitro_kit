module Gallery
  module Components
    class AvatarPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/avatar.rb"
      end

      def api_note
        "NitroKit::Avatar.new(src:, alt:, fallback:, size:)"
      end

      def component_template
        example_section(
          "Sizes",
          slug: "avatar-sizes",
          description: "All closed sizes keep fallback text, geometry, and accessibility semantics aligned."
        ) do
          example("Size scale", slug: "avatar-size-scale", layout: :matrix, density: :compact) do
            Gallery::Data.avatar_sizes.each do |avatar|
              sample(avatar.label, slug: avatar.slug) do
                render_avatar(avatar)
              end
            end
          end
        end

        example_section(
          "Images and fallbacks",
          slug: "avatar-content",
          description: "Image, generated initials, custom long fallback, and anonymous states are explicit."
        ) do
          example("Content modes", slug: "avatar-content-modes", layout: :matrix) do
            sample("Image", slug: "image") do
              render NitroKit::Avatar.new(
                src: "/icon.svg",
                alt: "Nitro Kit mark",
                fallback: "NK",
                size: :lg,
                id: "gallery-avatar-image"
              )
            end
            sample("Generated initials", slug: "generated-initials") do
              render NitroKit::Avatar.new(
                alt: "Alexandria Ocasio-Cortez",
                size: :lg,
                id: "gallery-avatar-generated"
              )
            end
            sample("Long custom fallback", slug: "long-fallback") do
              render NitroKit::Avatar.new(
                alt: "Platform engineering team",
                fallback: "TEAM",
                size: :lg,
                id: "gallery-avatar-long-fallback"
              )
            end
            sample("Anonymous", slug: "anonymous") do
              render NitroKit::Avatar.new(size: :lg, id: "gallery-avatar-anonymous")
            end
          end
        end

        example_section(
          "Accessible names",
          slug: "avatar-accessibility",
          description: "Fallback-only identities label the root; image identities retain native alt text."
        ) do
          example("Named identities", slug: "avatar-named-identities", layout: :row) do
            render NitroKit::Avatar.new(
              alt: "Katherine Johnson",
              fallback: "KJ",
              id: "gallery-avatar-labelled-fallback"
            )
            render NitroKit::Avatar.new(
              src: "/icon.svg",
              alt: "Nitro Kit workspace",
              fallback: "NK",
              id: "gallery-avatar-labelled-image"
            )
          end
        end
      end

      def render_avatar(avatar)
        render NitroKit::Avatar.new(
          src: avatar.src,
          alt: avatar.alt,
          fallback: avatar.fallback,
          size: avatar.size,
          id: "gallery-avatar-size-#{avatar.slug}"
        )
      end
    end
  end
end
