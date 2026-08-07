module Gallery
  module Components
    class ContainerPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/container.rb"
      end

      def api_note
        "NitroKit::Container.new(size: :sm | :md | :lg | :xl); omit Container for full-width content"
      end

      def component_template
        example_section(
          "Content widths",
          slug: "container-sizes",
          description: "Four existing content tokens provide centered maximum widths without arbitrary CSS values. The preview column is narrower than the lg and xl maximums, so those two clamp to the column here; widen the Responsive tab to see them diverge."
        ) do
          example("Every size", slug: "container-every-size", mode: :full_width) do
            render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-container-size-stack") do
              NitroKit::Container::SIZES.each do |size|
                render NitroKit::Container.new(size:, id: "gallery-container-size-#{size}") do
                  render NitroKit::Card.new(id: "gallery-container-size-#{size}-card") do |card|
                    card.title("#{size.to_s.upcase} content boundary", level: 4)
                    card.body("Uses --nk-content-#{size}; the surrounding application still owns available width.")
                  end
                end
              end
            end
          end
        end

        example_section(
          "Full-width boundary",
          slug: "container-full-width",
          description: "Full width is ordinary direct composition, not a fifth size or a special escape."
        ) do
          example(
            "Omit Container",
            slug: "container-omit-for-full",
            mode: :full_width,
            api: "render NitroKit::Card.new(...) # no Container wrapper"
          ) do
            render NitroKit::Card.new(id: "gallery-container-full-width-card") do |card|
              card.title("Full available width", level: 4)
              card.body("No data-nk=container ancestor is emitted for this surface.")
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "container-content",
          description: "A content boundary accepts empty, single, multiple, and long direct Phlex children."
        ) do
          example("Empty, one, and many", slug: "container-cardinality", layout: :matrix, mode: :full_width) do
            sample("Empty", slug: "empty") do
              render NitroKit::Container.new(size: :sm, id: "gallery-container-empty")
            end
            sample("One", slug: "one") do
              render NitroKit::Container.new(size: :sm, id: "gallery-container-one") do
                render NitroKit::Button.new(
                  "Intrinsic child",
                  id: "gallery-container-one-action",
                  variant: :primary
                )
              end
            end
            sample("Many", slug: "many") do
              render NitroKit::Container.new(size: :md, id: "gallery-container-many") do
                render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
                  6.times do |index|
                    render NitroKit::Alert.new(id: "gallery-container-many-#{index + 1}") do |alert|
                      alert.title("Queued operation #{index + 1}")
                      alert.description("Waiting for deterministic processing.")
                    end
                  end
                end
              end
            end
          end

          example("Long readable boundary", slug: "container-long-content", mode: :full_width) do
            render NitroKit::Container.new(size: :md, id: "gallery-container-long") do
              render NitroKit::Card.new(id: "gallery-container-long-card") do |card|
                card.title(
                  "Analytical Engines — International Research, Production, and Reliability Engineering",
                  level: 4
                )
                card.body do
                  p do
                    "This account description stays inside the same readable maximum width even when customer-owned " \
                      "identity and operational context are substantially longer than the common case."
                  end
                end
              end
            end
          end
        end

        example_section(
          "Nested compositions",
          slug: "container-nesting",
          description: "Container owns only maximum width; stacks, rows, and Grid retain their independent responsibilities."
        ) do
          example("Wide workspace collection", slug: "container-workspace-collection", mode: :full_width) do
            render NitroKit::Container.new(size: :xl, id: "gallery-container-composition") do
              render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
                render NitroKit::Flex.new(dir: :row, align: :center, gap: 2, justify: :between, wrap: :wrap) do
                  render NitroKit::Badge.new(
                    "12 active members",
                    id: "gallery-container-composition-status",
                    color: :success
                  )
                  render NitroKit::Button.new(
                    "Invite teammate",
                    id: "gallery-container-composition-action",
                    variant: :primary
                  )
                end
                render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-container-composition-grid") do
                  Gallery::Data.members.each do |member|
                    render NitroKit::Card.new(id: "gallery-container-composition-#{member.id}") do |card|
                      card.title(member.name, level: 4)
                      card.body("#{member.role.to_s.humanize} · #{member.email}")
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Evidence boundary",
          slug: "container-layout-boundary",
          description: "The first extraction wave stays smaller than the speculative vocabulary in the pivot plan."
        ) do
          example(
            "Deferred names",
            slug: "container-deferred-layouts",
            mode: :full_width,
            api: "No Spacer, Split, Frame, custom breakpoints, as:, or arbitrary CSS-value APIs"
          ) do
            render NitroKit::Container.new(size: :lg, id: "gallery-container-deferred") do
              render NitroKit::Alert.new(id: "gallery-container-deferred-alert") do |alert|
                alert.title("Three layout names remain deliberately unimplemented")
                alert.description(
                  "Spacer has no elastic-gap evidence and current rows use justify. Split appears in only one " \
                    "unsettled settings candidate. Frame has no flow evidence and would conflict with Turbo Frame language."
                )
              end
            end
          end
        end
      end
    end
  end
end
