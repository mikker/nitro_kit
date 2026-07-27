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
          "Long-form prose",
          slug: "typeset-long-form",
          description: "A complete document exercises every element the wrapper styles: heading levels, paragraphs, links, lists, a quotation, inline and block code, a table, and a rule."
        ) do
          example("Release note", slug: "typeset-release-note", mode: :full_width) do
            render NitroKit::Container.new(size: :md) do
              render NitroKit::Typeset.new(id: "gallery-typeset-release-note") do
                h1 { "Nitro Kit 2.0 is agent-native" }
                p do
                  plain "Nitro Kit 2.0 replaces generated component copies with a "
                  strong { "gem-owned" }
                  plain " library of Phlex components. A person and a coding agent now read the same contract, so the "
                  a(href: "#contract") { "component contract table" }
                  plain " is the whole API surface there is to learn."
                end

                h2 { "What changed" }
                p do
                  "Every component takes explicit keywords, validates its own vocabulary, and raises on anything it does not recognize. Nothing is silently ignored."
                end
                ul do
                  li do
                    plain "Options are closed sets. Passing "
                    code { "variant: :fancy" }
                    plain " raises an ArgumentError instead of rendering an unstyled control."
                  end
                  li { "Styling hangs off data attributes, so no class strings travel through your templates." }
                  li do
                    plain "Themes are ordinary custom properties under the "
                    code { "--nk-" }
                    plain " prefix."
                  end
                end

                h3 { "Rendering a component" }
                p { "Direct Phlex composition is the only public API:" }
                pre do
                  code do
                    plain <<~RUBY
                      render NitroKit::PageHeader.new(title: "Workspace members") do |header|
                        header.actions NitroKit::ButtonGroup.new(label: "Member actions") do |actions|
                          actions.button("Invite teammate", variant: :primary)
                        end
                      end
                    RUBY
                  end
                end

                h2 { "Upgrading" }
                ol do
                  li { "Remove the generated component directory from your application." }
                  li do
                    plain "Add the gem and run "
                    code { "bin/rails nitro_kit:install" }
                    plain "."
                  end
                  li { "Replace each helper call with the component it wrapped." }
                end
                blockquote do
                  p do
                    "The fastest way to make an interface legible to an agent is to make it legible to a person first."
                  end
                end

                hr

                h2 { "Support window" }
                table do
                  thead do
                    tr do
                      th { "Release" }
                      th { "Status" }
                      th { "Security fixes until" }
                    end
                  end
                  tbody do
                    tr do
                      td { "2.0" }
                      td { "Current" }
                      td { "Ongoing" }
                    end
                    tr do
                      td { "1.2" }
                      td { "Maintenance" }
                      td { "July 2027" }
                    end
                    tr do
                      td { "1.1" }
                      td { "Ended" }
                      td { "January 2026" }
                    end
                  end
                end
                p do
                  plain "Questions belong in the "
                  a(href: "#discussions") { "discussion board" }
                  plain "; regressions belong in an issue with a reproduction."
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
