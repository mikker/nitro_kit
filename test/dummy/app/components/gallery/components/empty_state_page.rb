module Gallery
  module Components
    class EmptyStatePage < ComponentPage
      private

      def component_template
        example_section(
          "Presentation",
          slug: "empty-state-presentation",
          description: "variant: is a closed vocabulary of default and borderless; any other value raises ArgumentError. The dashed default frames a standalone region and deliberately resembles a drop target, so prefer borderless whenever a Card, DataSection, table, or dialog already draws the frame — and never place the dashed default next to a real Dropzone."
        ) do
          example("Variant matrix", slug: "empty-state-variant-matrix", layout: :matrix) do
            sample("Default", slug: "default") do
              render NitroKit::EmptyState.new(
                title: "No saved views",
                description: "The dashed frame marks an otherwise unframed region of the page.",
                id: "gallery-empty-state-variant-default"
              ) do |empty|
                empty.icon NitroKit::Icon.new(:layout_grid)
              end
            end
            sample("Borderless", slug: "borderless") do
              render NitroKit::EmptyState.new(
                title: "No saved views",
                description: "Inside a frame of its own, the empty state drops its border and fill.",
                variant: :borderless,
                id: "gallery-empty-state-variant-borderless"
              ) do |empty|
                empty.icon NitroKit::Icon.new(:layout_grid)
              end
            end
          end

          example(
            "Borderless inside a card",
            slug: "empty-state-borderless-in-card",
            description: "The card owns the surface and border, so a dashed empty state inside it would read as a second, droppable surface."
          ) do
            render NitroKit::Card.new(id: "gallery-empty-state-card") do |card|
              card.title("Recent deployments", level: 3)
              card.body do
                render NitroKit::EmptyState.new(
                  title: "No deployments this week",
                  description: "Promote a release to see it listed here.",
                  variant: :borderless,
                  level: 4,
                  id: "gallery-empty-state-in-card"
                ) do |empty|
                  empty.icon NitroKit::Icon.new(:rocket)
                  empty.action NitroKit::Button.new("Promote a release", href: "#promote", variant: :primary)
                end
              end
            end
          end
        end

        example_section(
          "Optional content and actions",
          slug: "empty-state-pressure",
          description: "Heading levels, optional icon and description, and zero through two typed actions."
        ) do
          example("Title only", slug: "empty-state-title-only") do
            render NitroKit::EmptyState.new(title: "No records", id: "gallery-empty-state-title-only")
          end

          example("Informational", slug: "empty-state-information") do
            render NitroKit::EmptyState.new(
              title: "No API activity yet",
              description: "Requests will appear after a credential makes its first call.",
              id: "gallery-empty-state-information"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:activity)
            end
          end

          example("Primary action", slug: "empty-state-one-action") do
            render NitroKit::EmptyState.new(
              title: "No teammates yet",
              description: "Invite the first collaborator when the workspace is ready.",
              id: "gallery-empty-state-one-action"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:users)
              empty.action NitroKit::Button.new("Invite teammate", href: "#invite", variant: :primary)
            end
          end

          example("Primary and escape actions", slug: "empty-state-two-actions") do
            render NitroKit::EmptyState.new(
              title: "No matching invoices",
              description: "Change the date range or clear every filter to return to invoice history.",
              id: "gallery-empty-state-two-actions"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:search_x)
              empty.action NitroKit::Button.new("Clear filters", href: "#clear", variant: :primary)
              empty.action NitroKit::Button.new("Return to billing", href: "#billing")
            end
          end

          example("Long nested empty state", slug: "empty-state-long", mode: :full_width) do
            render NitroKit::Container.new(size: :md, id: "gallery-empty-state-long-container") do
              render NitroKit::EmptyState.new(
                level: 4,
                id: "gallery-empty-state-long"
              ) do |empty|
                empty.title do
                  plain "No records for "
                  strong { "International Research, Production, and Reliability Engineering" }
                end
                empty.description do
                  plain "The current search includes archived projects, suspended members, expired credentials, and a date range that predates this workspace. "
                  plain "Remove one or more filters before trying again."
                end
                empty.icon NitroKit::Icon.new(:database)
                empty.action NitroKit::Button.new("Reset all filters", href: "#reset", variant: :primary)
                empty.action NitroKit::Button.new("Review query guide", href: "#guide")
              end
            end
          end
        end
      end

      def source_note
        "EmptyState is content, not application policy: callers choose copy, destinations, and whether zero, one, or two actions are appropriate."
      end

      def api_note
        "Supply the required title through title: or title { ... }; description supports the same two forms. variant: accepts :default or :borderless and level: accepts 2..6. icon accepts one Icon and action accepts at most two distinct Buttons."
      end
    end
  end
end
