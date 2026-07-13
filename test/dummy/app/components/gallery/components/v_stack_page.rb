module Gallery
  module Components
    class VStackPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/v_stack.rb"
      end

      def api_note
        "NitroKit::VStack.new(gap: :none | :xs | :sm | :md | :lg | :xl, align: :start | :center | :stretch)"
      end

      def component_template
        example_section(
          "Gap scale",
          slug: "v-stack-gaps",
          description: "Six token-backed gaps cover the vertical rhythm repeated across forms, status handoffs, and records."
        ) do
          example("Every gap", slug: "v-stack-every-gap", layout: :matrix, mode: :full_width) do
            NitroKit::VStack::GAPS.each do |gap|
              sample(gap.to_s.humanize, slug: "gap-#{gap}") do
                render NitroKit::VStack.new(gap:, id: "gallery-v-stack-gap-#{gap}") do
                  3.times do |index|
                    render NitroKit::Badge.new(
                      "Item #{index + 1}",
                      id: "gallery-v-stack-gap-#{gap}-item-#{index + 1}",
                      variant: :outline
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Alignment and sizing",
          slug: "v-stack-alignment",
          description: "Start is deliberately intrinsic by default; center is explicit; stretch is an explicit placement decision."
        ) do
          example("Every alignment", slug: "v-stack-every-alignment", layout: :matrix, mode: :full_width) do
            NitroKit::VStack::ALIGNMENTS.each do |align|
              sample(align.to_s.humanize, slug: "align-#{align}") do
                render NitroKit::Container.new(size: :sm, id: "gallery-v-stack-#{align}-container") do
                  render NitroKit::VStack.new(
                    gap: :sm,
                    align:,
                    id: "gallery-v-stack-align-#{align}"
                  ) do
                    render NitroKit::Button.new(
                      "Short action",
                      id: "gallery-v-stack-align-#{align}-short"
                    )
                    render NitroKit::Button.new(
                      "Longer primary action",
                      id: "gallery-v-stack-align-#{align}-long",
                      variant: :primary
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "v-stack-content",
          description: "The same direct-content boundary supports empty, single, dense, and long compositions."
        ) do
          example("Empty, one, and many", slug: "v-stack-cardinality", layout: :matrix, mode: :full_width) do
            sample("Empty", slug: "empty") do
              render NitroKit::VStack.new(id: "gallery-v-stack-empty")
            end
            sample("One", slug: "one") do
              render NitroKit::VStack.new(id: "gallery-v-stack-one", align: :stretch) do
                render NitroKit::Card.new(id: "gallery-v-stack-one-card") do |card|
                  card.body("One surface remains a valid stack.")
                end
              end
            end
            sample("Many", slug: "many") do
              render NitroKit::VStack.new(gap: :xs, id: "gallery-v-stack-many") do
                12.times do |index|
                  render NitroKit::Badge.new(
                    "Queue #{index + 1}",
                    id: "gallery-v-stack-many-#{index + 1}",
                    size: :sm
                  )
                end
              end
            end
          end

          example("Long status composition", slug: "v-stack-long-status", mode: :full_width) do
            render NitroKit::Container.new(size: :md, id: "gallery-v-stack-long-container") do
              render NitroKit::VStack.new(gap: :lg, align: :stretch, id: "gallery-v-stack-long") do
                render NitroKit::Alert.new(id: "gallery-v-stack-long-alert", variant: :warning) do |alert|
                  alert.title("Credential rotation remains in progress across every production environment")
                  alert.description(
                    "This deliberately long operational message demonstrates natural wrapping without adding a " \
                      "long-content option to the layout primitive."
                  )
                end
                render NitroKit::Card.new(id: "gallery-v-stack-long-card") do |card|
                  card.title("Analytical Engines — International Research and Production", level: 4)
                  card.body("Three regions · twelve active members · seven connected deployment environments")
                end
              end
            end
          end
        end

        example_section(
          "Nested composition",
          slug: "v-stack-nesting",
          description: "Vertical rhythm composes with rows and the proven three-column collection without new slots."
        ) do
          example("Workspace summary", slug: "v-stack-workspace-summary", mode: :full_width) do
            render NitroKit::Container.new(size: :lg, id: "gallery-v-stack-composition-container") do
              render NitroKit::VStack.new(gap: :lg, align: :stretch, id: "gallery-v-stack-composition") do
                render NitroKit::HStack.new(
                  gap: :sm,
                  justify: :between,
                  wrap: true,
                  id: "gallery-v-stack-heading-row"
                ) do
                  render NitroKit::Badge.new(
                    "Operational",
                    id: "gallery-v-stack-heading-status",
                    color: :success
                  )
                  render NitroKit::Button.new(
                    "Open workspace",
                    id: "gallery-v-stack-heading-action",
                    variant: :primary
                  )
                end
                render NitroKit::Grid.new(cols: 3, id: "gallery-v-stack-metrics") do
                  %w[Members Deployments Requests].each_with_index do |label, index|
                    render NitroKit::Card.new(id: "gallery-v-stack-metric-#{index + 1}") do |card|
                      card.title(label, level: 4)
                      card.body([ "12", "18", "1,284,320" ].fetch(index))
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
