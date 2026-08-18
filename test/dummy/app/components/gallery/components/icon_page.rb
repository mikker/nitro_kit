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
            sample("Extra small save icon", slug: "xs") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-xs", size: :xs)
            end
            sample("Small save icon", slug: "sm") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-sm", size: :sm)
            end
            sample("Medium save icon", slug: "md") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-md", size: :md)
            end
            sample("Large save icon", slug: "lg") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-lg", size: :lg)
            end
            sample("Extra large save icon", slug: "xl") do
              render NitroKit::Icon.new(:flame, id: "gallery-icon-size-xl", size: :xl)
            end
          end
        end

        example_section(
          "Semantics",
          slug: "icon-semantics",
          description: "Label meaningful icons and leave icons hidden when nearby text carries the meaning."
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
              id: "gallery-icon-save-thin",
              stroke_width: 1,
              label: "Thin stroke"
            )
            render NitroKit::Icon.new(
              :flame,
              id: "gallery-icon-settings",
              stroke_width: 1.5,
              label: "Default stroke"
            )
            render NitroKit::Icon.new(
              :flame,
              id: "gallery-icon-warning-bold",
              stroke_width: 2,
              label: "Bold stroke"
            )
          end
        end
      end
    end
  end
end
