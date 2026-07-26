module Gallery
  module Components
    class DataSectionPage < ComponentPage
      private

      def component_template
        example_section(
          "Tables and empty alternatives",
          slug: "data-section-pressure",
          description: "Exactly one typed Table or level-three EmptyState with optional grouped actions."
        ) do
          example("Minimal table", slug: "data-section-minimal", mode: :full_width) do
            render NitroKit::DataSection.new(title: "Members", id: "gallery-data-section-minimal") do |section|
              section.table(member_table(id: "gallery-data-section-minimal-table", count: 1)) do |table|
                render_member_rows(table, 1)
              end
            end
          end

          example("Actions and complete table", slug: "data-section-complete", mode: :full_width) do
            render NitroKit::DataSection.new(
              title: "Workspace members",
              description: "Active, invited, and suspended access across every project.",
              id: "gallery-data-section-complete"
            ) do |section|
              section.actions NitroKit::ButtonGroup.new(label: "Member data actions") do |actions|
                actions.button("Export CSV", href: "#export")
                actions.button("Invite teammate", href: "#invite", variant: :primary)
              end
              section.table(member_table(id: "gallery-data-section-complete-table", count: 4)) do |table|
                render_member_rows(table, 4)
              end
            end
          end

          example("Empty alternative", slug: "data-section-empty", mode: :full_width) do
            render NitroKit::DataSection.new(
              title: "API credentials",
              description: "Credentials are scoped by environment and owner.",
              id: "gallery-data-section-empty"
            ) do |section|
              section.empty_state NitroKit::EmptyState.new(
                title: "No API credentials",
                description: "Create one when an integration is ready to authenticate.",
                level: 3,
                id: "gallery-data-section-empty-state"
              ) do |empty|
                empty.icon NitroKit::Icon.new(:key_round)
                empty.action NitroKit::Button.new("Create credential", href: "#create", variant: :primary)
              end
            end
          end

          example("Record details and a single action", slug: "data-section-details", mode: :full_width) do
            render NitroKit::DataSection.new(
              title: "Workspace profile",
              description: "A DetailsTable satisfies the same content boundary as a Table.",
              id: "gallery-data-section-details"
            ) do |section|
              section.actions NitroKit::Button.new("Edit profile", href: "#edit")
              section.table(
                NitroKit::DetailsTable.new(
                  Gallery::Data.members.first,
                  label: "Workspace profile",
                  id: "gallery-data-section-details-table"
                )
              ) do |details|
                details.fields(:name, :role, :status)
              end
            end
          end

          example("Dense long table", slug: "data-section-dense", mode: :full_width, density: :compact) do
            render NitroKit::Container.new(size: :xl, id: "gallery-data-section-dense-container") do
              render NitroKit::DataSection.new(
                title: "International workspace access inventory",
                description: "A deliberately dense table remains caller-owned while the section owns only its heading, actions, and content ordering.",
                id: "gallery-data-section-dense"
              ) do |section|
                section.actions NitroKit::ButtonGroup.new(label: "Inventory actions") do |actions|
                  actions.button("Download complete access inventory", href: "#download")
                end
                section.table(member_table(id: "gallery-data-section-dense-table", count: 12)) do |table|
                  render_member_rows(table, 12, long: true)
                end
              end
            end
          end
        end
      end

      def member_table(id:, count:)
        NitroKit::Table.new(id:, table_aria: { label: "#{count} workspace members" })
      end

      def render_member_rows(table, count, long: false)
        table.caption("Workspace access")
        table.thead do
          table.tr do
            table.th("Member")
            table.th("Role")
            table.th("Status")
            table.th("Projects", align: :right)
          end
        end
        table.tbody do
          count.times do |index|
            table.tr do
              table.th(long ? "Member #{index + 1} — International Reliability Engineering" : "Member #{index + 1}", scope: :row)
              table.td(index.zero? ? "Owner" : "Member")
              table.td do
                render NitroKit::Badge.new(index.even? ? "Active" : "Invited", color: index.even? ? :success : :info, size: :sm)
              end
              table.td(((index + 1) * 3).to_s, align: :right)
            end
          end
        end
      end

      def source_note
        "DataSection owns title → actions → content ordering. Tables, rows, EmptyState copy, and adjacent pagination remain caller-owned."
      end

      def api_note
        "Supply the required title and optional description through constructor text or matching compound methods. Provide exactly one table(Table or DetailsTable) or empty_state(EmptyState level: 3). actions accepts at most one Button or ButtonGroup."
      end
    end
  end
end
