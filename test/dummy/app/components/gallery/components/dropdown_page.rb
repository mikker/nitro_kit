module Gallery
  module Components
    class DropdownPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/dropdown.rb"
      end

      def api_note
        "NitroKit::Dropdown.new(id:) { |menu| menu.trigger; menu.item }"
      end

      def component_template
        example_section(
          "Placements",
          slug: "dropdown-placements",
          description: "Nitro JavaScript positions menus from their triggers; the native no-JavaScript baseline remains safely bounded."
        ) do
          example("Placement matrix", slug: "dropdown-placement-matrix", layout: :matrix) do
            NitroKit::Dropdown::PLACEMENTS.each do |placement|
              sample(placement.to_s.humanize, slug: placement.to_s) do
                render_menu("gallery-dropdown-#{placement}", placement:) do |menu|
                  menu.item("Open profile", href: "/gallery/profile")
                  menu.item("Copy account ID")
                end
              end
            end
          end
        end

        example_section(
          "Menu anatomy",
          slug: "dropdown-anatomy",
          description: "Titles, links, buttons, separators, disabled items, and destructive intent remain native."
        ) do
          example("Account actions", slug: "dropdown-account-actions") do
            render NitroKit::Dropdown.new(id: "gallery-dropdown-account") do |menu|
              menu.trigger("Account actions", variant: :primary)
              menu.title("Workspace")
              menu.item("Workspace settings", href: "/gallery/settings")
              menu.item("Duplicate workspace")
              menu.item("Export audit log", disabled: true)
              menu.separator
              menu.title("Danger zone")
              menu.item("Delete workspace", variant: :destructive)
            end
          end
        end

        example_section(
          "Icon triggers and icon items",
          slug: "dropdown-icons",
          description: "The compact overflow menu is an icon-only Button trigger with icon-led items."
        ) do
          example("Overflow menu", slug: "dropdown-overflow-menu", layout: :matrix) do
            sample("Icon-only trigger", slug: "icon-only-trigger") do
              render NitroKit::Dropdown.new(id: "gallery-dropdown-overflow", placement: :bottom_end) do |menu|
                menu.trigger(icon: :ellipsis, label: "Record actions", variant: :ghost)
                menu.item("Rename record", icon: :pencil)
                menu.item("Duplicate record", icon: :copy)
                menu.separator
                menu.item("Delete record", icon: :trash_2, variant: :destructive)
              end
            end
            sample("Trailing trigger icon", slug: "trailing-trigger-icon") do
              render NitroKit::Dropdown.new(id: "gallery-dropdown-sort") do |menu|
                menu.trigger("Sort by", icon_end: :chevron_down)
                menu.item("Newest first", icon: :arrow_down)
                menu.item("Oldest first", icon: :arrow_up)
              end
            end
          end
        end

        example_section(
          "Availability and pressure",
          slug: "dropdown-pressure",
          description: "A disabled trigger and long labels exercise non-interactive and constrained states."
        ) do
          example("Edge states", slug: "dropdown-edge-states", layout: :matrix) do
            sample("Disabled trigger", slug: "disabled-trigger") do
              render NitroKit::Dropdown.new(id: "gallery-dropdown-disabled") do |menu|
                menu.trigger("Actions unavailable", disabled: true)
                menu.item("Unavailable action", disabled: true)
              end
            end
            sample("Long content", slug: "long-content") do
              render NitroKit::Dropdown.new(id: "gallery-dropdown-long") do |menu|
                menu.trigger("Deployment actions")
                menu.item("Promote the currently verified release to production")
                menu.item("Restore the previously healthy production release", variant: :destructive)
              end
            end
          end
        end

        example_section(
          "Record composition",
          slug: "dropdown-record",
          description: "Card, Badge, and Dropdown compose into a realistic deployment record."
        ) do
          example("Production deployment", slug: "dropdown-deployment-card") do
            render NitroKit::Card.new(id: "gallery-dropdown-deployment-card") do |card|
              card.title("Release 2026.07.13", level: 3)
              card.body do
                render NitroKit::Badge.new(
                  "Healthy",
                  id: "gallery-dropdown-deployment-status",
                  color: :success,
                  size: :sm
                )
                p { "Serving all workspaces from fra1 and iad1." }
              end
              card.footer do
                render NitroKit::Dropdown.new(id: "gallery-dropdown-deployment") do |menu|
                  menu.trigger("Release actions", variant: :ghost)
                  menu.item("View deployment", href: "/gallery/deployments/2026-07-13")
                  menu.item("Copy release identifier")
                  menu.separator
                  menu.item("Roll back release", variant: :destructive)
                end
              end
            end
          end
        end
      end

      def render_menu(id, placement: :bottom_start, &entries)
        render NitroKit::Dropdown.new(id:, placement:) do |menu|
          menu.trigger(placement.to_s.humanize)
          entries.call(menu)
        end
      end
    end
  end
end
