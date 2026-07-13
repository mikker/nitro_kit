module Gallery
  module Components
    class BadgePage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/badge.rb"
      end

      def api_note
        "NitroKit::Badge.new(label, variant:, size:, color:)"
      end

      def component_template
        example_section(
          "Colors",
          slug: "badge-colors",
          description: "Every semantic color keeps compact state legible without application classes."
        ) do
          example("Color matrix", slug: "badge-color-matrix", layout: :matrix, density: :compact) do
            Gallery::Data.badge_colors.each do |badge|
              sample(badge.label, slug: badge.slug) do
                render_badge(badge, id: "gallery-badge-color-#{badge.slug}")
              end
            end
          end
        end

        example_section(
          "Variants and sizes",
          slug: "badge-presentation",
          description: "Both variants and both sizes are closed, visible presentation choices."
        ) do
          example("Variant matrix", slug: "badge-variant-matrix", layout: :matrix, density: :compact) do
            Gallery::Data.badge_variants.each do |badge|
              sample(badge.label, slug: badge.slug) do
                render_badge(badge, id: "gallery-badge-variant-#{badge.slug}")
              end
            end
          end
          example("Size scale", slug: "badge-size-scale", layout: :row, density: :compact) do
            Gallery::Data.badge_sizes.each do |badge|
              render_badge(badge, id: "gallery-badge-size-#{badge.slug}")
            end
          end
        end

        example_section(
          "Content modes",
          slug: "badge-content",
          description: "Scalar, block, numeric, nested icon, and long product labels use the same label slot."
        ) do
          example("Label content", slug: "badge-label-content", layout: :matrix) do
            sample("Scalar", slug: "scalar") do
              render NitroKit::Badge.new(
                "Ready",
                id: "gallery-badge-scalar",
                color: :success
              )
            end
            sample("Block", slug: "block") do
              render NitroKit::Badge.new(
                id: "gallery-badge-block",
                variant: :outline,
                color: :info
              ) { "Generated from a Phlex block" }
            end
            sample("Numeric", slug: "numeric") do
              render NitroKit::Badge.new(128, id: "gallery-badge-numeric", color: :neutral)
            end
            sample("Nested icon", slug: "nested-icon") do
              render NitroKit::Badge.new(id: "gallery-badge-nested-icon", color: :success) do
                render NitroKit::Icon.new(:lock, id: "gallery-badge-lock-icon", size: :xs)
                plain " Secured"
              end
            end
            sample("Long label", slug: "long-label") do
              render NitroKit::Badge.new(
                "Awaiting production deployment approval from a workspace administrator",
                id: "gallery-badge-long-label",
                variant: :outline,
                color: :warning
              )
            end
          end
        end

        example_section(
          "Roster composition",
          slug: "badge-roster",
          description: "Table, Avatar, and Badge compose into a realistic member-status roster."
        ) do
          example("Workspace roster", slug: "badge-workspace-roster", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-badge-roster-table",
              table_html: { id: "gallery-badge-roster-table-element" }
            ) do |table|
              table.caption("Workspace roster")
              table.thead do
                table.tr do
                  table.th("Person")
                  table.th("Role")
                  table.th("Status", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.members.each do |member|
                  table.tr do
                    table.th(scope: :row) do
                      render NitroKit::Avatar.new(
                        alt: member.name,
                        size: :sm,
                        id: "gallery-badge-roster-avatar-#{member.id}"
                      )
                      plain " #{member.name}"
                    end
                    table.td(member.role.to_s.humanize)
                    table.td(align: :right) do
                      render NitroKit::Badge.new(
                        member.status.to_s.humanize,
                        id: "gallery-badge-roster-status-#{member.id}",
                        color: member_status_color(member.status),
                        size: :sm
                      )
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_badge(badge, id:)
        render NitroKit::Badge.new(
          badge.label,
          id:,
          variant: badge.variant,
          size: badge.size,
          color: badge.color
        )
      end

      def member_status_color(status)
        { active: :success, invited: :info }.fetch(status)
      end
    end
  end
end
