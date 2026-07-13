module Gallery
  module Blocks
    class ToolbarPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/toolbar.rb"
      end

      def api_note
        "NitroKit::Toolbar.new { |toolbar| toolbar.leading { ... }; toolbar.trailing { ... } } # one or both regions"
      end

      def component_template
        example_section(
          "Region combinations",
          slug: "toolbar-regions",
          description: "Leading and trailing are independently optional, may each appear once, and remain neutral content regions."
        ) do
          example("Every valid region shape", slug: "toolbar-valid-regions", layout: :matrix, mode: :full_width) do
            sample("Leading only", slug: "leading-only") do
              render NitroKit::Toolbar.new(id: "gallery-toolbar-leading-only") do |toolbar|
                toolbar.leading do
                  render NitroKit::Badge.new("12 active members", id: "gallery-toolbar-leading-count", color: :success)
                end
              end
            end
            sample("Trailing only", slug: "trailing-only") do
              render NitroKit::Toolbar.new(id: "gallery-toolbar-trailing-only") do |toolbar|
                toolbar.trailing do
                  render NitroKit::Button.new(
                    "Save changes",
                    id: "gallery-toolbar-trailing-save",
                    variant: :primary
                  )
                end
              end
            end
            sample("Leading and trailing", slug: "split") do
              render NitroKit::Toolbar.new(id: "gallery-toolbar-split") do |toolbar|
                toolbar.leading { h3 { "Workspace members" } }
                toolbar.trailing do
                  render NitroKit::ButtonGroup.new(label: "Member collection actions") do |group|
                    group.button("Export", id: "gallery-toolbar-split-export")
                    group.button("Invite", id: "gallery-toolbar-split-invite", variant: :primary)
                  end
                end
              end
            end
          end
        end

        example_section(
          "Wrapping and narrow pressure",
          slug: "toolbar-pressure",
          description: "The root and both regions wrap at wide sizes, then stack at the shared 48rem narrow condition."
        ) do
          example(
            "Long record controls",
            slug: "toolbar-long-controls",
            mode: :full_width,
            api: "No role=toolbar; ordinary links and buttons retain native tab order"
          ) do
            render NitroKit::Toolbar.new(id: "gallery-toolbar-long") do |toolbar|
              toolbar.leading do
                h3 { "Analytical Engines — International Research, Production, and Reliability Engineering" }
                render NitroKit::Badge.new(
                  "Credential rotation in progress",
                  id: "gallery-toolbar-long-status",
                  color: :warning
                )
              end
              toolbar.trailing do
                render NitroKit::ButtonGroup.new(label: "Long workspace actions") do |group|
                  group.button("Review organization access policy", id: "gallery-toolbar-long-policy")
                  group.button("Invite an international research administrator", id: "gallery-toolbar-long-invite")
                  group.button("Open production security report", id: "gallery-toolbar-long-report", variant: :primary)
                end
              end
            end
          end

          example("Dense actions", slug: "toolbar-dense", mode: :full_width, density: :compact) do
            render NitroKit::Toolbar.new(id: "gallery-toolbar-dense") do |toolbar|
              toolbar.leading do
                8.times do |index|
                  render NitroKit::Badge.new(
                    "Filter #{index + 1}",
                    id: "gallery-toolbar-dense-filter-#{index + 1}",
                    size: :sm,
                    variant: :outline
                  )
                end
              end
              toolbar.trailing do
                5.times do |index|
                  render NitroKit::Button.new(
                    "Action #{index + 1}",
                    id: "gallery-toolbar-dense-action-#{index + 1}",
                    size: :sm
                  )
                end
              end
            end
          end
        end

        example_section(
          "Real compositions",
          slug: "toolbar-compositions",
          description: "Collection headings and form actions use the same placement boundary without arrays or action registries."
        ) do
          example("Collection heading", slug: "toolbar-collection", mode: :full_width) do
            render NitroKit::Card.new(id: "gallery-toolbar-collection-card") do |card|
              card.body do
                render NitroKit::Toolbar.new(id: "gallery-toolbar-collection") do |toolbar|
                  toolbar.leading do
                    h3 { "API credentials" }
                    render NitroKit::Badge.new("4 active", id: "gallery-toolbar-collection-count", color: :info)
                  end
                  toolbar.trailing do
                    render NitroKit::Button.new(
                      "Create credential",
                      id: "gallery-toolbar-collection-create",
                      variant: :primary
                    )
                  end
                end
              end
            end
          end

          example("Form actions", slug: "toolbar-form-actions", mode: :full_width) do
            render NitroKit::Container.new(size: :md) do
              render NitroKit::Card.new(id: "gallery-toolbar-form-card") do |card|
                card.title("Profile", level: 4)
                card.body do
                  render NitroKit::Toolbar.new(id: "gallery-toolbar-form") do |toolbar|
                    toolbar.leading do
                      render NitroKit::Badge.new("Unsaved changes", id: "gallery-toolbar-form-status", color: :warning)
                    end
                    toolbar.trailing do
                      render NitroKit::Button.new("Discard", id: "gallery-toolbar-form-discard", variant: :ghost)
                      render NitroKit::Button.new("Save profile", id: "gallery-toolbar-form-save", variant: :primary)
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
