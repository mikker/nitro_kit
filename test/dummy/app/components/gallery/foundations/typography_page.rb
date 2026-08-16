module Gallery
  module Foundations
    class TypographyPage < FoundationPage
      TYPE_SIZES = %i[xs sm base lg xl 2xl].freeze
      WEIGHTS = %i[normal medium semibold bold].freeze
      LEADINGS = %i[tight normal relaxed].freeze

      TITLE_ROLES = [
        [ :page, "The one page heading", "PageHeader" ],
        [ :section, "Full-width section headers", "DataSection, SettingsSection, DangerZone" ],
        [ :surface, "Panels and fieldsets", "Card, Dialog, Sheet, EmptyState, Fieldset" ],
        [ :compact, "Legends and status titles", "Alert, Toast, CheckboxGroup, RadioButtonGroup, AppearancePicker" ]
      ].freeze

      private

      def source_note
        "src/stylesheets/nitro_kit/tokens.css"
      end

      def api_note
        "var(--nk-text-{size}), var(--nk-font-weight-{weight}), var(--nk-leading-{leading}), and var(--nk-title-{role}-{size,weight})"
      end

      def foundation_template
        example_section(
          "Type scale",
          slug: "type-scale",
          description: "Six sizes cover every owned text decision."
        ) do
          example("Every text size", slug: "text-size-scale", mode: :full_width) do
            TYPE_SIZES.each do |size|
              type_specimen(
                "The quick brown fox jumps over the lazy dog",
                token: "--nk-text-#{size}",
                style: "--gallery-type-size: var(--nk-text-#{size})"
              )
            end
          end
        end

        example_section(
          "Weights and leading",
          slug: "weights-leading",
          description: "Four weights and three leadings pair with the scale."
        ) do
          example("Every weight", slug: "font-weight-scale", mode: :full_width) do
            WEIGHTS.each do |weight|
              type_specimen(
                "Signals over ceremony",
                token: "--nk-font-weight-#{weight}",
                style: "--gallery-type-weight: var(--nk-font-weight-#{weight})"
              )
            end
          end

          example("Every leading", slug: "leading-scale", mode: :full_width) do
            LEADINGS.each do |leading|
              type_specimen(
                "Lines set close read as one thought. Lines set open read as a list. The leading decides before the words do.",
                token: "--nk-leading-#{leading}",
                style: "--gallery-type-leading: var(--nk-leading-#{leading})"
              )
            end
          end
        end

        example_section(
          "Title roles",
          slug: "title-roles",
          description: "Every owned title and legend samples one of four roles, so the hierarchy is stated once and themeable."
        ) do
          example("Every title role", slug: "title-role-scale", mode: :full_width) do
            TITLE_ROLES.each do |role, job, consumers|
              figure(data: { gallery: "title-specimen", gallery_title_role: role }) do
                figcaption do
                  strong { role.to_s.capitalize }
                  code { "--nk-title-#{role}-size" }
                end
                p(data: { gallery: "title-specimen-text" }) { job }
                small { consumers }
              end
            end
          end

          example("A surface title in context", slug: "title-role-context") do
            render NitroKit::Card.new(id: "gallery-typography-card") do |card|
              card.title("Quarterly invoices")
              card.body { plain "The card title above samples the surface role." }
            end
          end
        end
      end

      def type_specimen(text, token:, style:)
        figure(data: { gallery: "title-specimen" }) do
          figcaption { code { token } }
          p(style:, data: { gallery: "type-chip" }) { text }
        end
      end
    end
  end
end
