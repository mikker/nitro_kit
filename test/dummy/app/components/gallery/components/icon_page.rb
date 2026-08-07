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
              render NitroKit::Icon.new(:save, id: "gallery-icon-size-xs", size: :xs)
            end
            sample("Small save icon", slug: "sm") do
              render NitroKit::Icon.new(:save, id: "gallery-icon-size-sm", size: :sm)
            end
            sample("Medium save icon", slug: "md") do
              render NitroKit::Icon.new(:save, id: "gallery-icon-size-md", size: :md)
            end
            sample("Large save icon", slug: "lg") do
              render NitroKit::Icon.new(:save, id: "gallery-icon-size-lg", size: :lg)
            end
            sample("Extra large save icon", slug: "xl") do
              render NitroKit::Icon.new(:save, id: "gallery-icon-size-xl", size: :xl)
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
                :circle_check,
                id: "gallery-icon-meaningful",
                size: :lg,
                label: "Deployment succeeded"
              )
            end
            sample("Decorative", slug: "decorative") do
              render NitroKit::Icon.new(:arrow_right, id: "gallery-icon-decorative", size: :lg)
            end
          end
        end

        example_section(
          "Stroke and glyphs",
          slug: "icon-glyphs",
          description: "A small representative set demonstrates name normalization and deliberate stroke weight."
        ) do
          example("Interface glyphs", slug: "icon-interface-glyphs", layout: :row) do
            render NitroKit::Icon.new(
              :save,
              id: "gallery-icon-save-thin",
              stroke_width: 1,
              label: "Save"
            )
            render NitroKit::Icon.new(
              :settings,
              id: "gallery-icon-settings",
              stroke_width: 1.5,
              label: "Settings"
            )
            render NitroKit::Icon.new(
              :triangle_alert,
              id: "gallery-icon-warning-bold",
              stroke_width: 2,
              label: "Warning"
            )
          end
        end
      end
    end
  end
end
