module Gallery
  module Foundations
    class EffectsPage < FoundationPage
      ELEVATION_STEPS = [
        [ "xs", "Raised controls", "Button" ],
        [ "sm", "Resting surfaces", "Card, Tooltip" ],
        [ "md", "Floating elements", "Dropdown, Combobox, Toast" ],
        [ "lg", "Modal surfaces", "Dialog, CommandPalette, Sheet" ]
      ].freeze

      private

      def source_note
        "src/stylesheets/nitro_kit/tokens.css"
      end

      def api_note
        "var(--nk-shadow-{step}) and var(--nk-disabled-opacity)"
      end

      def foundation_template
        example_section(
          "Elevation",
          slug: "elevation-scale",
          description: "Four shadow steps form the depth ladder. Every surface sits on one rung."
        ) do
          example("Every shadow step", slug: "elevation-shadow-scale", mode: :full_width, layout: :matrix, density: :compact) do
            ELEVATION_STEPS.each do |step, tier, consumers|
              figure(data: { gallery: "depth" }) do
                span(
                  aria: { hidden: true },
                  style: "--gallery-shadow: var(--nk-shadow-#{step})",
                  data: { gallery: "depth-chip" }
                )
                figcaption do
                  strong { tier }
                  code { "--nk-shadow-#{step}" }
                  small { consumers }
                end
              end
            end
          end
        end

        example_section(
          "Disabled state",
          slug: "disabled-state",
          description: "One opacity covers every disabled control."
        ) do
          example("Enabled and disabled", slug: "disabled-opacity", layout: :row, api: "var(--nk-disabled-opacity)") do
            render NitroKit::Button.new("Save changes", id: "gallery-foundation-enabled")
            render NitroKit::Button.new("Save changes", id: "gallery-foundation-disabled", disabled: true)
          end
        end
      end
    end
  end
end
