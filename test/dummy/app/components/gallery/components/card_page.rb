module Gallery
  module Components
    class CardPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/card.rb"
      end

      def api_note
        "NitroKit::Card.new { |card| card.title; card.body; card.footer }"
      end

      def component_template
        example_section(
          "Anatomy",
          slug: "card-anatomy",
          description: "The card owns structural slots while headings and application content remain ordinary Phlex."
        ) do
          example("Complete structure", slug: "card-complete-structure", layout: :matrix) do
            sample("Title, body, divider, footer", slug: "complete") do
              render NitroKit::Card.new(id: "gallery-card-workspace") do |card|
                card.title("Mothership workspace", level: 3)
                card.body { "12 active members · Team plan" }
                card.divider
                card.footer { "Renews August 1, 2026" }
              end
            end
            sample("Body only", slug: "body-only") do
              render NitroKit::Card.new(id: "gallery-card-body-only") do |card|
                card.body { "A quiet surface can omit title and footer slots." }
              end
            end
          end
        end

        example_section(
          "Content modes",
          slug: "card-content",
          description: "Cards support full-width regions and long product content without assuming its internal markup."
        ) do
          example("Full-width region", slug: "card-full-width-region") do
            render NitroKit::Card.new(id: "gallery-card-activity") do |card|
              card.title("Weekly activity", level: 3)
              card.full do
                card.body("Chart placeholder · 1,284 events")
              end
              card.footer("Updated July 13, 2026 at 08:42 UTC")
            end
          end

          example("Long content", slug: "card-long-content") do
            render NitroKit::Card.new(id: "gallery-card-long-content") do |card|
              card.title(
                "A workspace name that remains understandable when translated or supplied by a customer",
                level: 3
              )
              card.body do
                p do
                  "This description deliberately spans multiple lines so the surface demonstrates natural wrapping " \
                    "without a special long-content mode or application utility classes."
                end
              end
              card.footer("Last reviewed by Ada Lovelace")
            end
          end
        end

        example_section(
          "Heading levels",
          slug: "card-heading-levels",
          description: "The title slot emits the requested semantic heading level from one through six."
        ) do
          example("Complete title scale", slug: "card-title-scale", layout: :matrix, density: :compact) do
            (1..6).each do |level|
              sample("Heading level #{level}", slug: "heading-#{level}") do
                render NitroKit::Card.new(id: "gallery-card-heading-#{level}") do |card|
                  card.title("Level #{level} title", level:)
                  card.body { "Card titles follow the surrounding document hierarchy." }
                end
              end
            end
          end
        end

        example_section(
          "Slot boundaries",
          slug: "card-slot-boundaries",
          description: "Individual slots and useful partial structures remain valid without placeholder content."
        ) do
          example("Partial structures", slug: "card-partial-structures", layout: :matrix) do
            sample("Empty surface", slug: "empty") do
              render NitroKit::Card.new(id: "gallery-card-empty") { nil }
            end
            sample("Title only", slug: "title-only") do
              render NitroKit::Card.new(id: "gallery-card-title-only") do |card|
                card.title("A title without supporting content", level: 3)
              end
            end
            sample("Footer only", slug: "footer-only") do
              render NitroKit::Card.new(id: "gallery-card-footer-only") do |card|
                card.footer("Last synchronized July 13, 2026")
              end
            end
            sample("Body and footer", slug: "body-footer") do
              render NitroKit::Card.new(id: "gallery-card-body-footer") do |card|
                card.body("Three pending invitations")
                card.footer("Review access before the next billing cycle")
              end
            end
            sample("Full-width only", slug: "full-only") do
              render NitroKit::Card.new(id: "gallery-card-full-only") do |card|
                card.full { "A full-width region can be the only declared slot." }
              end
            end
          end
        end

        example_section(
          "Record composition",
          slug: "card-record",
          description: "Status, structured record metadata, and related actions nest without changing card anatomy."
        ) do
          example("Integration detail", slug: "card-integration-detail") do
            integration = Gallery::Data.integrations.fetch(1)

            render NitroKit::Card.new(id: "gallery-card-integration") do |card|
              card.title(integration.name, level: 3)
              card.body do
                render NitroKit::Badge.new(
                  "Action required",
                  id: "gallery-card-integration-status",
                  color: :warning,
                  size: :sm
                )
                p { integration.description }
                dl do
                  dt { "Connected" }
                  dd { integration.connected_at.iso8601 }
                  dt { "Delivery target" }
                  dd { "Team operations channel" }
                end
              end
              card.divider
              card.footer do
                render NitroKit::ButtonGroup.new(
                  id: "gallery-card-integration-actions",
                  label: "Slack integration actions"
                ) do |group|
                  group.button(
                    "Reconnect",
                    id: "gallery-card-integration-reconnect",
                    variant: :primary,
                    size: :sm,
                    icon: :refresh_cw
                  )
                  group.button(
                    "Disconnect",
                    id: "gallery-card-integration-disconnect",
                    variant: :destructive,
                    size: :sm
                  )
                end
              end
            end
          end
        end

        example_section(
          "Form composition",
          slug: "card-form",
          description: "Card, Field, Input, and Button compose directly into a native profile form."
        ) do
          example("Profile settings", slug: "card-profile-form") do
            render NitroKit::Card.new(id: "gallery-card-profile-form-card") do |card|
              card.title("Profile", level: 3)
              card.body do
                form(id: "gallery-card-profile-form", action: "#profile", method: "post") do
                  render NitroKit::FieldGroup.new do
                    render NitroKit::Field.new(
                      nil,
                      :name,
                      id: "gallery-card-profile-name",
                      name: "profile[name]",
                      value: "Ada Lovelace",
                      label: "Name",
                      autocomplete: "name",
                      required: true,
                      html: { id: "gallery-card-profile-name-field" }
                    )
                    render NitroKit::Field.new(
                      nil,
                      :email,
                      as: :email,
                      id: "gallery-card-profile-email",
                      name: "profile[email]",
                      value: "ada@example.test",
                      label: "Email",
                      description: "Used for security notices and account recovery.",
                      autocomplete: "email",
                      required: true,
                      html: { id: "gallery-card-profile-email-field" }
                    )
                  end
                end
              end
              card.footer do
                render NitroKit::Button.new(
                  "Save profile",
                  id: "gallery-card-profile-save",
                  type: :submit,
                  form: "gallery-card-profile-form",
                  variant: :primary,
                  icon: :save
                )
                render NitroKit::Button.new(
                  "Reset",
                  id: "gallery-card-profile-reset",
                  type: :reset,
                  form: "gallery-card-profile-form",
                )
              end
            end
          end
        end
      end
    end
  end
end
