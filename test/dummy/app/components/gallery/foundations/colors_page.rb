module Gallery
  module Foundations
    class ColorsPage < FoundationPage
      STEPS = %i[50 100 200 300 400 500 600 700 800 900 950].freeze
      NEUTRAL_FAMILIES = %i[slate gray zinc neutral stone].freeze
      COLOR_FAMILIES = %i[
        red orange amber yellow lime green emerald teal cyan sky blue indigo
        violet purple fuchsia pink rose
      ].freeze

      private

      def source_note
        "src/stylesheets/nitro_kit/tokens.css"
      end

      def api_note
        "var(--nk-{family}-{step}) and var(--nk-palette-{color})"
      end

      def foundation_template
        render NitroKit::Alert.new(
          id: "gallery-color-attribution",
          variant: :info,
          title: "Palette provenance",
          description: "These scales are harmonized derivations of the Tailwind CSS v4 palette, used under its MIT license—not unchanged copies. Nitro Kit smooths each family’s OKLCH lightness, chroma, and hue while keeping every value imperceptibly close to its Tailwind source."
        )

        example_section(
          "Poles",
          slug: "color-poles",
          description: "White and black anchor pure surfaces, foregrounds, and overlays and can be rethemed independently."
        ) do
          example("White and black", slug: "color-poles", layout: :row) do
            %i[white black].each { |color| color_swatch(color, token: "--nk-#{color}") }
          end
        end

        example_section(
          "Neutral scales",
          slug: "neutral-color-scales",
          description: "Cool through warm neutral ramps for canvas, surface, border, and content roles."
        ) do
          example("Neutral families", slug: "neutral-color-families", mode: :full_width, scroll: true) do
            NEUTRAL_FAMILIES.each { |family| color_scale(family) }
          end
        end

        example_section(
          "Color scales",
          slug: "color-scales",
          description: "Every public family includes all eleven appearance-independent steps. Use 50–200 for tints and surfaces, 400–600 for accents and markers, and 700–950 for content."
        ) do
          example("Color families", slug: "color-families", mode: :full_width, scroll: true) do
            COLOR_FAMILIES.each { |family| color_scale(family) }
          end
        end

        example_section(
          "Tint palette",
          slug: "color-tint-palette",
          description: "Badge, Alert, and Toast share these semantic and decorative tint roles. Semantic names follow application meaning; hue names remain literal."
        ) do
          example("Palette roles", slug: "color-palette-roles", mode: :full_width, layout: :matrix, density: :compact) do
            NitroKit::Badge::COLORS.each do |color|
              render NitroKit::Badge.new(
                "--nk-palette-#{color}",
                id: "gallery-color-palette-#{color}",
                color:
              )
            end
          end
        end
      end

      def color_scale(family)
        figure(data: { gallery: "color-scale", gallery_color_family: family }) do
          figcaption do
            strong { family.to_s.capitalize }
            code { "--nk-#{family}-{step}" }
          end
          div(role: "list", data: { gallery: "color-swatches" }) do
            STEPS.each do |step|
              color_swatch(step, token: "--nk-#{family}-#{step}")
            end
          end
        end
      end

      def color_swatch(label, token:)
        div(role: "listitem", data: { gallery: "color-swatch", gallery_color_token: token }) do
          span(
            aria: { hidden: true },
            style: "--gallery-color: var(#{token})",
            data: { gallery: "color-chip" }
          )
          code { label.to_s }
        end
      end
    end
  end
end
