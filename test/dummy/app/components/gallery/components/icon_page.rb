module Gallery
  module Components
    class IconPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/icon.rb"
      end

      def api_note
        "NitroKit::Icon.new(name, size:, label:)"
      end

      def component_template
        example_section(
          "Sizes",
          slug: "icon-sizes",
          description: "The closed size scale keeps icon geometry predictable inside controls and content."
        ) do
          example("Size scale", slug: "icon-size-scale", layout: :matrix, density: :compact) do
            sample("Extra small", slug: "xs") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-xs", size: :xs)
            end
            sample("Small", slug: "sm") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-sm", size: :sm)
            end
            sample("Medium", slug: "md") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-md", size: :md)
            end
            sample("Large", slug: "lg") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-lg", size: :lg)
            end
            sample("Extra large", slug: "xl") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-xl", size: :xl)
            end
          end
        end

        example_section(
          "Semantics",
          slug: "icon-semantics",
          description: "The pair renders identically; the difference is what assistive technology hears. label: makes an icon an image with an accessible name, and without it the icon stays hidden decoration beside its own text."
        ) do
          example("Meaningful and decorative", slug: "icon-meaning", layout: :matrix) do
            sample("Meaningful", slug: "meaningful") do
              render NitroKit::Icon.new(
                :flame,
                id: "gallery-icon-meaningful",
                size: :lg,
                label: "Trending this week"
              )
            end
            sample("Decorative", slug: "decorative") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-decorative", size: :lg)
            end
          end
        end

        example_section(
          "Stroke and glyphs",
          slug: "icon-glyphs",
          description: "One glyph across the stroke range shows the weight decision on its own."
        ) do
          example("Interface glyphs", slug: "icon-interface-glyphs", layout: :row) do
            render NitroKit::Icon.new(
              :flame,
              id: "gallery-icon-stroke-thin",
              stroke_width: 1,
              label: "Thin stroke"
            )
            render NitroKit::Icon.new(
              :flame,
              id: "gallery-icon-stroke-default",
              stroke_width: 1.5,
              label: "Default stroke"
            )
            render NitroKit::Icon.new(
              :flame,
              id: "gallery-icon-stroke-bold",
              stroke_width: 2,
              label: "Bold stroke"
            )
          end
        end
      end
    end
  end
end
