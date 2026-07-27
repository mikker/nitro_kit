module Gallery
  module Components
    class GridPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/grid.rb"
      end

      def api_note
        'NitroKit::Grid.new(cols: "1 sm:2 lg:3", gap: "2 md:4")'
      end

      def component_template
        example_section(
          "Mobile-first columns",
          slug: "grid-responsive",
          description: "Column and gap values use the same base, sm, md, lg, xl, and 2xl shorthand as Flex."
        ) do
          example(
            "One to three cards",
            slug: "grid-card-collection",
            mode: :full_width,
            api: 'cols: "1 sm:2 lg:3", gap: "3 md:4 lg:6"'
          ) do
            render NitroKit::Container.new(size: :xl) do
              render NitroKit::Grid.new(
                cols: "1 sm:2 lg:3",
                gap: "3 md:4 lg:6",
                id: "gallery-grid-cards"
              ) do
                Gallery::Data.plans.each do |plan|
                  render NitroKit::Card.new(id: "gallery-grid-card-#{plan.id}") do |card|
                    card.title(plan.name, level: 4)
                    card.body(plan.features.to_sentence)
                    card.footer do
                      render NitroKit::Button.new(
                        plan.current ? "Manage" : "Choose",
                        variant: plan.current ? :default : :primary
                      )
                    end
                  end
                end
              end
            end
          end

          example("Every breakpoint", slug: "grid-every-breakpoint", mode: :full_width, scroll: true) do
            render NitroKit::Grid.new(
              cols: "1 sm:2 md:3 lg:4 xl:6 2xl:12",
              gap: "1 sm:2 md:3 lg:4 xl:6 2xl:8",
              id: "gallery-grid-breakpoints"
            ) do
              12.times do |index|
                render NitroKit::Badge.new(
                  "Track #{index + 1}",
                  id: "gallery-grid-breakpoint-#{index + 1}",
                  variant: :outline
                )
              end
            end
          end
        end

        example_section(
          "Scalar columns",
          slug: "grid-scalar-columns",
          description: "A scalar keeps one column count at every viewport; the closed range is one through twelve."
        ) do
          # Six counts side by side leaves the wider grids a few characters
          # each, so every count takes its own row.
          example("Representative counts", slug: "grid-column-counts", layout: :stack, mode: :full_width, scroll: true) do
            [ 1, 2, 3, 4, 6, 12 ].each do |cols|
              sample("#{cols} #{'column'.pluralize(cols)}", slug: "cols-#{cols}") do
                render NitroKit::Grid.new(cols:, gap: 1, id: "gallery-grid-cols-#{cols}") do
                  cols.times do |index|
                    render NitroKit::Badge.new(
                      "#{index + 1}",
                      id: "gallery-grid-cols-#{cols}-#{index + 1}",
                      color: :info
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Independent responsive decisions",
          slug: "grid-combinations",
          description: "Columns and spacing can change at different breakpoints without exposing arbitrary CSS values."
        ) do
          example("Two useful collection shapes", slug: "grid-collection-shapes", layout: :stack, mode: :full_width) do
            sample("Catalog", slug: "catalog") do
              render NitroKit::Grid.new(
                cols: "1 md:2 xl:4",
                gap: "2 lg:6",
                id: "gallery-grid-catalog"
              ) do
                8.times do |index|
                  render NitroKit::Card.new(id: "gallery-grid-catalog-#{index + 1}") do |card|
                    card.title("Integration #{index + 1}", level: 4)
                    card.body("A roomy card collection gains columns gradually.")
                  end
                end
              end
            end

            sample("Metrics", slug: "metrics") do
              render NitroKit::Grid.new(
                cols: "2 lg:4 2xl:6",
                gap: "2 md:3",
                id: "gallery-grid-metrics"
              ) do
                12.times do |index|
                  render NitroKit::Card.new(id: "gallery-grid-metric-#{index + 1}") do |card|
                    card.title("Region #{index + 1}", level: 4)
                    card.body("#{(index + 1) * 128_430} requests")
                  end
                end
              end
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "grid-pressure",
          description: "Empty, partial, dense, and uneven collections retain the declared responsive contract."
        ) do
          example("Empty, one, and many", slug: "grid-cardinality", layout: :stack, mode: :full_width) do
            sample("Empty", slug: "empty") do
              render NitroKit::Grid.new(cols: "1 md:3", gap: 4, id: "gallery-grid-empty")
            end
            sample("One", slug: "one") do
              render NitroKit::Grid.new(cols: "1 md:3", gap: 4, id: "gallery-grid-one") do
                render NitroKit::Card.new do |card|
                  card.body("One item occupies one track; Grid does not invent a span API.")
                end
              end
            end
            sample("Many", slug: "many") do
              render NitroKit::Grid.new(cols: "1 sm:2 lg:3", gap: 2, id: "gallery-grid-many") do
                9.times do |index|
                  render NitroKit::Card.new do |card|
                    card.title("Record #{index + 1}", level: 4)
                    card.body("Deterministic collection item")
                  end
                end
              end
            end
          end

          example("Uneven team records", slug: "grid-team-records", mode: :full_width) do
            render NitroKit::Grid.new(
              cols: "1 sm:2 lg:3",
              gap: "3 lg:6",
              id: "gallery-grid-team"
            ) do
              Gallery::Data.members.each do |member|
                render NitroKit::Card.new(id: "gallery-grid-team-#{member.id}") do |card|
                  card.title(member.name, level: 4)
                  card.body do
                    render NitroKit::Flex.new(dir: :col, gap: 2, align: :start) do
                      render NitroKit::Badge.new(
                        member.status.to_s.humanize,
                        color: member.status == :active ? :success : :info
                      )
                      p { member.email }
                      p { "International Research, Production, and Reliability Engineering" } if member == Gallery::Data.members.first
                    end
                  end
                  card.footer do
                    render NitroKit::Flex.new(dir: :row, gap: 1, align: :center, wrap: :wrap) do
                      render NitroKit::Button.new("View", size: :sm)
                      render NitroKit::Button.new("Change role", size: :sm)
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
