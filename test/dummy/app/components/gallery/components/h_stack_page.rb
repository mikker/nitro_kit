module Gallery
  module Components
    class HStackPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/h_stack.rb"
      end

      def api_note
        "NitroKit::HStack.new(gap:, align: :start | :center | :stretch, justify: :start | :end | :between, wrap: true | false)"
      end

      def component_template
        example_section(
          "Gap scale",
          slug: "h-stack-gaps",
          description: "Rows use the same six spacing decisions as vertical stacks."
        ) do
          example("Every gap", slug: "h-stack-every-gap", layout: :matrix, mode: :full_width) do
            NitroKit::HStack::GAPS.each do |gap|
              sample(gap.to_s.humanize, slug: "gap-#{gap}") do
                render NitroKit::HStack.new(gap:, id: "gallery-h-stack-gap-#{gap}") do
                  3.times do |index|
                    render NitroKit::Badge.new(
                      "#{index + 1}",
                      id: "gallery-h-stack-gap-#{gap}-#{index + 1}",
                      variant: :outline
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Alignment",
          slug: "h-stack-alignment",
          description: "Start, center, and stretch cover the repeated row relationships without baseline or end variants."
        ) do
          example("Every alignment", slug: "h-stack-every-alignment", layout: :matrix, mode: :full_width) do
            NitroKit::HStack::ALIGNMENTS.each do |align|
              sample(align.to_s.humanize, slug: "align-#{align}") do
                render NitroKit::HStack.new(
                  gap: :sm,
                  align:,
                  id: "gallery-h-stack-align-#{align}"
                ) do
                  render NitroKit::Card.new(id: "gallery-h-stack-align-#{align}-short") do |card|
                    card.body("Short")
                  end
                  render NitroKit::Card.new(id: "gallery-h-stack-align-#{align}-long") do |card|
                    card.body do
                      p { "A second surface carries enough copy to create a visibly taller row item." }
                      p { "Stretch is therefore observable and deliberate." }
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Distribution",
          slug: "h-stack-justification",
          description: "Three evidence-backed distributions cover leading actions, trailing actions, and split header rows."
        ) do
          example("Every justification", slug: "h-stack-every-justification", layout: :matrix, mode: :full_width) do
            NitroKit::HStack::JUSTIFICATIONS.each do |justify|
              sample(justify.to_s.humanize, slug: "justify-#{justify}") do
                render NitroKit::Container.new(size: :sm, id: "gallery-h-stack-justify-#{justify}-container") do
                  render NitroKit::HStack.new(
                    gap: :sm,
                    justify:,
                    id: "gallery-h-stack-justify-#{justify}"
                  ) do
                    render NitroKit::Button.new("Previous", id: "gallery-h-stack-#{justify}-previous")
                    render NitroKit::Button.new(
                      "Continue",
                      id: "gallery-h-stack-#{justify}-continue",
                      variant: :primary
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Wrapping and cardinality",
          slug: "h-stack-wrapping",
          description: "Wrapping is an explicit boolean; no-wrap remains predictable under dense and long content."
        ) do
          example("Wrap states", slug: "h-stack-wrap-states", layout: :matrix, mode: :full_width, scroll: true) do
            [ false, true ].each do |wrap|
              sample(wrap ? "Wrap" : "No wrap", slug: wrap ? "wrap" : "no-wrap") do
                render NitroKit::Container.new(size: :sm, id: "gallery-h-stack-wrap-#{wrap}-container") do
                  render NitroKit::HStack.new(
                    gap: :sm,
                    wrap:,
                    id: "gallery-h-stack-wrap-#{wrap}"
                  ) do
                    8.times do |index|
                      render NitroKit::Button.new(
                        "Environment #{index + 1}",
                        id: "gallery-h-stack-wrap-#{wrap}-#{index + 1}",
                        size: :sm,
                        variant: index.zero? ? :primary : :default
                      )
                    end
                  end
                end
              end
            end
          end

          example("Empty, one, and many", slug: "h-stack-cardinality", layout: :matrix, mode: :full_width) do
            sample("Empty", slug: "empty") do
              render NitroKit::HStack.new(id: "gallery-h-stack-empty")
            end
            sample("One", slug: "one") do
              render NitroKit::HStack.new(id: "gallery-h-stack-one") do
                render NitroKit::Badge.new("Only", id: "gallery-h-stack-one-badge")
              end
            end
            sample("Many and long", slug: "many-long") do
              render NitroKit::HStack.new(
                gap: :xs,
                wrap: true,
                id: "gallery-h-stack-many-long"
              ) do
                Gallery::Data.integrations.each do |integration|
                  render NitroKit::Badge.new(
                    "#{integration.name} — #{integration.status.to_s.humanize}",
                    id: "gallery-h-stack-integration-#{integration.id}",
                    color: :info
                  )
                end
              end
            end
          end
        end

        example_section(
          "Nested composition",
          slug: "h-stack-nesting",
          description: "Rows remain intrinsic inside a stretched page rhythm and a token-sized content boundary."
        ) do
          example("Record heading and actions", slug: "h-stack-record-heading", mode: :full_width) do
            render NitroKit::Container.new(size: :lg, id: "gallery-h-stack-record-container") do
              render NitroKit::VStack.new(gap: :md, align: :stretch, id: "gallery-h-stack-record-stack") do
                render NitroKit::Card.new(id: "gallery-h-stack-record-card") do |card|
                  card.title("Production API credential", level: 4)
                  card.body do
                    render NitroKit::HStack.new(
                      gap: :sm,
                      justify: :between,
                      wrap: true,
                      id: "gallery-h-stack-record-row"
                    ) do
                      render NitroKit::Badge.new(
                        "Read and write",
                        id: "gallery-h-stack-record-access",
                        color: :warning
                      )
                      render NitroKit::HStack.new(gap: :xs, wrap: true, id: "gallery-h-stack-record-actions") do
                        render NitroKit::Button.new("Rotate", id: "gallery-h-stack-record-rotate", size: :sm)
                        render NitroKit::Button.new(
                          "Revoke",
                          id: "gallery-h-stack-record-revoke",
                          size: :sm,
                          variant: :destructive
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
