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

        example_section(
          "Under pressure",
          slug: "data-section-stress",
          description: "An unbroken hundred-letter title, four paragraphs of description, all twelve hostile actions, and a forty-row table of Gallery::Hostile names, emails, badges, and extreme amounts."
        ) do
          example("Hostile section", slug: "data-section-hostile", mode: :full_width, stress: true) do
            render NitroKit::DataSection.new(
              title: Gallery::Hostile::LONG_WORD,
              description: Gallery::Hostile::LONG_PARAGRAPH,
              id: "gallery-data-section-hostile"
            ) do |section|
              section.actions NitroKit::ButtonGroup.new(id: "gallery-data-section-hostile-actions", label: "Every member action") do |actions|
                Gallery::Hostile::ACTION_LABELS.each_with_index do |label, index|
                  actions.button(
                    label,
                    id: "gallery-data-section-hostile-action-#{index + 1}",
                    href: "#hostile-member-action-#{index + 1}",
                    size: :sm
                  )
                end
              end
              section.table(
                NitroKit::Table.new(
                  id: "gallery-data-section-hostile-table",
                  table_aria: { label: "40 hostile workspace members" }
                )
              ) do |table|
                table.caption(Gallery::Hostile::LONG_LABEL)
                table.thead do
                  table.tr do
                    table.th("Member")
                    table.th("Email")
                    table.th("Status")
                    table.th("Balance", align: :right)
                  end
                end
                table.tbody do
                  Gallery::Hostile.members(40).each_with_index do |member, index|
                    table.tr do
                      table.th(member.name, scope: :row)
                      table.td(member.email)
                      table.td do
                        render NitroKit::Badge.new(
                          Gallery::Hostile::BADGE_LABELS.fetch(index % Gallery::Hostile::BADGE_LABELS.size),
                          id: "gallery-data-section-hostile-status-#{index + 1}",
                          color: member.status == :active ? :success : :warning,
                          size: :sm
                        )
                      end
                      table.td(index.even? ? Gallery::Hostile::HUGE_MONEY : Gallery::Hostile::NEGATIVE_MONEY, align: :right)
                    end
                  end
                end
              end
            end
          end
        end
      end

      def member_table(id:, count:)
        NitroKit::Table.new(id:, table_aria: { label: "#{count} #{"workspace member".pluralize(count)}" })
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
