module Gallery
  module Components
    class GridPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/grid.rb"
      end

      def api_note
        "NitroKit::Grid.new(cols: 3) # one proven collection shape; automatically stacks at narrow viewport width"
      end

      def component_template
        example_section(
          "Evidence-backed columns",
          slug: "grid-columns",
          description: "Dashboard metrics and plan comparisons prove one three-column collection; unsupported counts fail."
        ) do
          example("Three-column metrics", slug: "grid-three-columns", mode: :full_width) do
            render NitroKit::Container.new(size: :lg, id: "gallery-grid-metrics-container") do
              render NitroKit::Grid.new(cols: 3, id: "gallery-grid-metrics") do
                [
                  [ "Active members", "12", "Two invitations pending" ],
                  [ "Deployments", "18", "Four to production" ],
                  [ "API requests", "1,284,320", "62% of monthly allowance" ]
                ].each_with_index do |(title, value, detail), index|
                  render NitroKit::Card.new(id: "gallery-grid-metric-#{index + 1}") do |card|
                    card.title(title, level: 4)
                    card.body do
                      strong { value }
                      p { detail }
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Responsive contract",
          slug: "grid-responsive",
          description: "The same three tracks become one track at the Nitro-owned 48rem narrow condition; no public breakpoint API exists."
        ) do
          example(
            "Resize without changing Ruby",
            slug: "grid-responsive-collapse",
            mode: :full_width,
            source: "src/stylesheets/nitro_kit/components/grid.css",
            api: "Grid owns repeat(3, minmax(0, 1fr)) and a single max-width: 48rem collapse"
          ) do
            render NitroKit::Grid.new(cols: 3, id: "gallery-grid-responsive") do
              Gallery::Data.plans.each do |plan|
                render NitroKit::Card.new(id: "gallery-grid-responsive-#{plan.id}") do |card|
                  card.title(plan.name, level: 4)
                  card.body do
                    p { plan.features.to_sentence }
                    render NitroKit::Badge.new(
                      plan.current ? "Current" : "Available",
                      id: "gallery-grid-responsive-#{plan.id}-status",
                      color: plan.current ? :success : :neutral
                    )
                  end
                  card.footer do
                    render NitroKit::Button.new(
                      plan.current ? "Manage" : "Choose",
                      id: "gallery-grid-responsive-#{plan.id}-action",
                      variant: plan.current ? :default : :primary
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Cardinality",
          slug: "grid-cardinality",
          description: "Empty, partial, complete, and overflow rows keep the same stable three-track contract."
        ) do
          example("Empty, one, and many", slug: "grid-cardinality-states", layout: :matrix, mode: :full_width) do
            sample("Empty", slug: "empty") do
              render NitroKit::Grid.new(cols: 3, id: "gallery-grid-empty")
            end
            sample("One", slug: "one") do
              render NitroKit::Grid.new(cols: 3, id: "gallery-grid-one") do
                render NitroKit::Card.new(id: "gallery-grid-one-card") do |card|
                  card.body("One item occupies one track; Grid does not invent a span API.")
                end
              end
            end
            sample("Many", slug: "many") do
              render NitroKit::Grid.new(cols: 3, id: "gallery-grid-many") do
                9.times do |index|
                  render NitroKit::Card.new(id: "gallery-grid-many-#{index + 1}") do |card|
                    card.title("Record #{index + 1}", level: 4)
                    card.body("Deterministic collection item")
                  end
                end
              end
            end
          end
        end

        example_section(
          "Long and uneven content",
          slug: "grid-pressure",
          description: "Tracks use minmax(0, 1fr), so customer text wraps without forcing arbitrary width controls."
        ) do
          example("Uneven operational records", slug: "grid-uneven-records", mode: :full_width) do
            render NitroKit::Grid.new(cols: 3, id: "gallery-grid-uneven") do
              Gallery::Data.integrations.each_with_index do |integration, index|
                render NitroKit::Card.new(id: "gallery-grid-integration-#{integration.id}") do |card|
                  card.title(
                    index == 1 ? "#{integration.name} workspace notifications and administrative approvals" : integration.name,
                    level: 4
                  )
                  card.body do
                    render NitroKit::VStack.new(gap: :sm, align: :start, id: "gallery-grid-integration-#{index + 1}-body") do
                      render NitroKit::Badge.new(
                        integration.status.to_s.humanize,
                        id: "gallery-grid-integration-#{index + 1}-status",
                        color: index == 1 ? :danger : :info
                      )
                      p do
                        "#{integration.description} This connection applies to Analytical Engines — International " \
                          "Research, Production, and Reliability Engineering."
                      end
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Nested composition",
          slug: "grid-nesting",
          description: "Grid assigns tracks while stacks continue to own rhythm and action placement inside each item."
        ) do
          example("Team records", slug: "grid-team-records", mode: :full_width) do
            render NitroKit::Container.new(size: :xl, id: "gallery-grid-team-container") do
              render NitroKit::Grid.new(cols: 3, id: "gallery-grid-team") do
                Gallery::Data.members.each do |member|
                  render NitroKit::Card.new(id: "gallery-grid-team-#{member.id}") do |card|
                    card.title(member.name, level: 4)
                    card.body do
                      render NitroKit::VStack.new(gap: :sm, align: :start) do
                        render NitroKit::Badge.new(
                          member.status.to_s.humanize,
                          id: "gallery-grid-team-#{member.id}-status",
                          color: member.status == :active ? :success : :info
                        )
                        p { member.email }
                      end
                    end
                    card.footer do
                      render NitroKit::HStack.new(gap: :xs, wrap: true) do
                        render NitroKit::Button.new(
                          "View",
                          id: "gallery-grid-team-#{member.id}-view",
                          size: :sm
                        )
                        render NitroKit::Button.new(
                          "Change role",
                          id: "gallery-grid-team-#{member.id}-role",
                          size: :sm,
                          variant: :ghost
                        )
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
