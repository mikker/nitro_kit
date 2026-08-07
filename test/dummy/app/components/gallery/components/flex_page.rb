module Gallery
  module Components
    class FlexPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/flex.rb"
      end

      def api_note
        'NitroKit::Flex.new(dir: "col md:row", gap: "2 md:4", align:, justify:, wrap:)'
      end

      def component_template
        example_section(
          "Mobile-first shorthand",
          slug: "flex-responsive",
          description: "Each property accepts a base value followed by the fixed sm md lg xl 2xl breakpoint prefixes; omitted breakpoints inherit the previous value."
        ) do
          example(
            "One layout, three arrangements",
            slug: "flex-responsive-arrangement",
            mode: :full_width,
            api: 'dir: "col md:row", gap: "2 md:4 lg:6", align: "stretch md:center", justify: "start lg:between"'
          ) do
            render NitroKit::Container.new(size: :lg) do
              render NitroKit::Flex.new(
                dir: "col md:row",
                gap: "2 md:4 lg:6",
                align: "stretch md:center",
                justify: "start lg:between",
                wrap: "nowrap md:wrap",
                id: "gallery-flex-responsive"
              ) do
                render NitroKit::Card.new(id: "gallery-flex-responsive-summary") do |card|
                  card.title("Production workspace", level: 4)
                  card.body("Stacks on small screens, then becomes a row without application CSS.")
                end
                render NitroKit::Badge.new(
                  "12 active members",
                  id: "gallery-flex-responsive-status",
                  color: :success
                )
                render NitroKit::Button.new(
                  "Open workspace",
                  id: "gallery-flex-responsive-action",
                  variant: :primary
                )
              end
            end
          end

          example(
            "Every breakpoint and property",
            slug: "flex-every-breakpoint",
            mode: :full_width,
            api: "base + sm + md + lg + xl + 2xl"
          ) do
            render NitroKit::Flex.new(
              dir: "col sm:row md:row-reverse lg:col-reverse xl:row 2xl:col",
              gap: "1 sm:2 md:4 lg:8 xl:12 2xl:16",
              align: "start sm:center md:end lg:stretch xl:baseline 2xl:center",
              justify: "start sm:center md:end lg:between xl:around 2xl:evenly",
              wrap: "nowrap sm:wrap md:wrap-reverse lg:nowrap xl:wrap 2xl:wrap-reverse",
              id: "gallery-flex-breakpoints"
            ) do
              6.times do |index|
                render NitroKit::Badge.new(
                  "Region #{index + 1}",
                  id: "gallery-flex-breakpoint-#{index + 1}",
                  variant: :outline
                )
              end
            end
          end
        end

        example_section(
          "Direction",
          slug: "flex-direction",
          description: "Rows, columns, and their reverse forms share one primitive and the same responsive grammar."
        ) do
          example("Every direction", slug: "flex-every-direction", layout: :matrix, mode: :full_width) do
            %w[row col row-reverse col-reverse].each do |direction|
              sample(direction.humanize, slug: direction) do
                render NitroKit::Flex.new(
                  dir: direction,
                  gap: 2,
                  align: :start,
                  id: "gallery-flex-dir-#{direction}"
                ) do
                  3.times do |index|
                    render NitroKit::Badge.new(
                      "Item #{index + 1}",
                      id: "gallery-flex-dir-#{direction}-#{index + 1}",
                      variant: :outline
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Gap and alignment",
          slug: "flex-gap-alignment",
          description: "Numeric gaps follow Nitro's spacing unit. Alignment includes start, center, end, stretch, and baseline."
        ) do
          example("Responsive gap", slug: "flex-responsive-gap", mode: :full_width) do
            render NitroKit::Flex.new(
              dir: :row,
              gap: "1 sm:2 md:4 lg:8 xl:12 2xl:16",
              align: :center,
              wrap: :wrap,
              id: "gallery-flex-gap-responsive"
            ) do
              6.times do |index|
                render NitroKit::Badge.new(
                  "Space #{index + 1}",
                  id: "gallery-flex-gap-responsive-#{index + 1}",
                  color: :info
                )
              end
            end
          end

          # Cross-axis alignment only reads when a sample owns a full row; a
          # matrix squeezes the two cards until the difference disappears.
          example("Every alignment", slug: "flex-every-alignment", layout: :stack, mode: :full_width) do
            %w[start center end stretch baseline].each do |alignment|
              sample(alignment.humanize, slug: alignment) do
                render NitroKit::Flex.new(
                  dir: :row,
                  gap: 2,
                  align: alignment,
                  id: "gallery-flex-align-#{alignment}"
                ) do
                  render NitroKit::Card.new do |card|
                    card.body("Short")
                  end
                  render NitroKit::Card.new do |card|
                    card.body do
                      strong { "Taller surface" }
                      p { "A second line makes cross-axis alignment visible." }
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Distribution and wrapping",
          slug: "flex-distribution",
          description: "Justification and wrapping remain independent, responsive decisions."
        ) do
          example("Every justification", slug: "flex-every-justification", layout: :matrix, mode: :full_width) do
            %w[start center end between around evenly].each do |justification|
              sample(justification.humanize, slug: justification) do
                render NitroKit::Flex.new(
                  dir: :row,
                  gap: 2,
                  align: :center,
                  justify: justification,
                  id: "gallery-flex-justify-#{justification}"
                ) do
                  render NitroKit::Button.new("Previous", size: :sm)
                  render NitroKit::Button.new("Continue", size: :sm, variant: :primary)
                end
              end
            end
          end

          example("Every wrap mode", slug: "flex-every-wrap", layout: :stack, mode: :full_width) do
            %w[nowrap wrap wrap-reverse].each do |wrap|
              sample(wrap.humanize, slug: wrap) do
                render NitroKit::Container.new(size: :sm) do
                  render NitroKit::Flex.new(
                    dir: :row,
                    gap: 2,
                    align: :center,
                    wrap:,
                    id: "gallery-flex-wrap-#{wrap}"
                  ) do
                    8.times do |index|
                      render NitroKit::Button.new("Environment #{index + 1}", size: :sm)
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Application composition",
          slug: "flex-composition",
          description: "Responsive properties combine for familiar headers and action regions without utility classes."
        ) do
          example("Workspace heading", slug: "flex-workspace-heading", mode: :full_width) do
            render NitroKit::Container.new(size: :xl) do
              render NitroKit::Flex.new(
                dir: "col lg:row",
                gap: "4 lg:6",
                align: "stretch lg:center",
                justify: "start lg:between",
                id: "gallery-flex-composition"
              ) do
                render NitroKit::Flex.new(dir: :col, gap: 1, align: :start) do
                  render NitroKit::Badge.new("Operational", color: :success)
                  h3 { "Analytical Engines" }
                  p { "International Research, Production, and Reliability Engineering" }
                end
                render NitroKit::Flex.new(
                  dir: :row,
                  gap: 2,
                  align: :center,
                  justify: :end,
                  wrap: :wrap,
                  id: "gallery-flex-composition-actions"
                ) do
                  render NitroKit::Button.new("View activity")
                  render NitroKit::Button.new("Create deployment", variant: :primary)
                end
              end
            end
          end
        end
      end
    end
  end
end
