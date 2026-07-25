module Gallery
  module Components
    class TypesetPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/typeset.rb"
      end

      def api_note
        "NitroKit::Typeset.new { plain HTML or rendered rich content }"
      end

      def component_template
        example_section(
          "Rendered content",
          slug: "typeset-content",
          description: "One wrapper gives ordinary semantic HTML a coherent reading rhythm."
        ) do
          example("Article", slug: "typeset-article") do
            render NitroKit::Container.new(size: :md) do
              render NitroKit::Typeset.new(id: "gallery-typeset-article") do
                h1 { "A system for durable interfaces" }
                p do
                  "Typed components give people and coding agents the same " \
                    "small, dependable vocabulary."
                end
                h2 { "What the wrapper owns" }
                ul do
                  li { "Reading rhythm and heading scale" }
                  li { "Lists, links, code, quotes, and tables" }
                  li { "Theme-aware color and typography tokens" }
                end
                blockquote do
                  "The surrounding Container still owns the readable measure."
                end
              end
            end
          end
        end

        example_section(
          "Application boundaries",
          slug: "typeset-boundaries",
          description: "Nested Nitro components and explicit data-typeset=off regions keep their own styling."
        ) do
          example("Embedded component", slug: "typeset-embedded-component") do
            render NitroKit::Typeset.new(id: "gallery-typeset-boundary") do
              p { "Rich content can introduce an application-owned action." }
              render NitroKit::Card.new(id: "gallery-typeset-card") do |card|
                card.title("Continue in the application")
                card.body { render NitroKit::Button.new("Open workspace") }
              end
              div(data: { typeset: "off" }, id: "gallery-typeset-opt-out") do
                h3 { "Explicitly unformatted region" }
              end
            end
          end
        end
      end
    end
  end
end
