module Gallery
  module Foundations
    class EffectsPage < FoundationPage
      ELEVATION_STEPS = [
        [ "xs", "Raised controls", "Button" ],
        [ "sm", "Resting surfaces", "Card, Tooltip" ],
        [ "md", "Floating elements", "Dropdown, Combobox, Toast" ],
        [ "lg", "Modal surfaces", "Dialog, CommandPalette, Sheet" ]
      ].freeze

      RADIUS_STEPS = [
        [ "xs", "Inline chips", "Typeset code" ],
        [ "sm", "Compact controls", "Checkbox" ],
        [ "md", "Data-entry controls and menus", "Input, Select, Dropdown, Badge" ],
        [ "lg", "Actions and surfaces", "Button, Card, Alert, Toast" ],
        [ "xl", "Modal surfaces", "Dialog, extra-large Button" ],
        [ "full", "Pills and circles", "Avatar, Switch, RadioButton" ]
      ].freeze

      DURATION_STEPS = [
        [ "fast", "Micro feedback", "Accordion chevron, tab highlight" ],
        [ "normal", "Interactive state", "Controls, overlays, toasts" ],
        [ "slow", "Large movement", "Sheet, app shell drawer" ]
      ].freeze

      private

      def source_note
        "src/stylesheets/nitro_kit/tokens.css"
      end

      def api_note
        "var(--nk-radius-{step}), var(--nk-shadow-{step}), var(--nk-duration-{speed}), var(--nk-ease)"
      end

      def foundation_template
        example_section(
          "Radius",
          slug: "radius-scale",
          description: "Five sizes and a circle. Radii move together when a theme changes shape, and --nk-button-radius separates button shape when a pill treatment should not recolor inputs and surfaces."
        ) do
          example("Every radius step", slug: "radius-shape-scale", mode: :full_width, layout: :matrix, density: :compact) do
            RADIUS_STEPS.each do |step, tier, consumers|
              figure(data: { gallery: "depth" }) do
                span(
                  aria: { hidden: true },
                  style: "--gallery-radius: var(--nk-radius-#{step})",
                  data: { gallery: "radius-chip" }
                )
                figcaption do
                  strong { tier }
                  code { "--nk-radius-#{step}" }
                  small { consumers }
                end
              end
            end
          end
        end

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
          "Motion",
          slug: "motion-scale",
          description: "Three durations and one deliberate easing curve, interruptible in both directions. Every transition stands down under prefers-reduced-motion, including these demos."
        ) do
          example("Every duration step", slug: "motion-duration-scale", mode: :full_width, layout: :matrix, density: :compact) do
            DURATION_STEPS.each do |speed, tier, consumers|
              figure(data: { gallery: "depth" }) do
                span(aria: { hidden: true }, style: "--gallery-duration: var(--nk-duration-#{speed})", data: { gallery: "motion-chip" }) do
                  span(data: { gallery: "motion-chip-handle" })
                end
                figcaption do
                  strong { tier }
                  code { "--nk-duration-#{speed}" }
                  small { consumers }
                end
              end
            end
            figure(data: { gallery: "depth" }) do
              span(aria: { hidden: true }, data: { gallery: "motion-ease" }) { code { "cubic-bezier(0.4, 0, 0.2, 1)" } }
              figcaption do
                strong { "One curve, both directions" }
                code { "--nk-ease" }
                small { "Enter and exit stay reversible" }
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
