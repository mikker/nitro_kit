module Gallery
  module Blocks
    class StatGridPage < ComponentPage
      private

      def component_template
        example_section(
          "Cardinality and content pressure",
          slug: "stat-grid-pressure",
          description: "The deliberately narrow keyed stat record across one, partial, complete, dense, and long data."
        ) do
          example("One stat", slug: "stat-grid-one") do
            render NitroKit::StatGrid.new(id: "gallery-stat-grid-one") do |stats|
              stats.stat(key: :members, label: "Members", value: "1")
            end
          end

          example("Partial row", slug: "stat-grid-two") do
            render NitroKit::StatGrid.new(id: "gallery-stat-grid-two") do |stats|
              stats.stat(key: :members, label: "Members", value: "18", detail: "2 invitations pending")
              stats.stat(key: :projects, label: "Active projects", value: "7")
            end
          end

          example("Complete row", slug: "stat-grid-three", mode: :full_width) do
            render NitroKit::StatGrid.new(id: "gallery-stat-grid-three") do |stats|
              stats.stat(key: :monthly_requests, label: "Monthly requests", value: "1,284,902", detail: "Current billing period")
              stats.stat(key: :error_rate, label: "Error rate", value: "0.08%", detail: "Past 24 hours")
              stats.stat(key: :uptime, label: "Uptime", value: "99.99%", detail: "Past 30 days")
            end
          end

          example("Dense records", slug: "stat-grid-dense", mode: :full_width, density: :compact) do
            render NitroKit::StatGrid.new(id: "gallery-stat-grid-dense") do |stats|
              9.times do |index|
                stats.stat(
                  key: "region-#{index + 1}",
                  label: "Region #{index + 1}",
                  value: ((index + 1) * 12_345).to_s,
                  detail: index.even? ? "Healthy" : nil
                )
              end
            end
          end

          example("Long values nested in content", slug: "stat-grid-long", mode: :full_width) do
            render NitroKit::Container.new(size: :lg, id: "gallery-stat-grid-long-container") do
              render NitroKit::StatGrid.new(id: "gallery-stat-grid-long") do |stats|
                stats.stat(key: :retention, label: "Annual enterprise data retention", value: "365 days", detail: "Applies to International Research and Reliability Engineering")
                stats.stat(key: :storage, label: "Encrypted object storage", value: "8,192.75 GB", detail: "Replicated across three regions")
                stats.stat(key: :events, label: "Audit events awaiting export", value: "2,147,483,647", detail: "Export before the regulatory deadline")
              end
            end
          end
        end
      end

      def source_note
        "StatGrid composes the proven three-column Grid and owns its narrow collapse. It does not own trends, charts, colors, or policy."
      end

      def api_note
        "stat(key:, label:, value:, detail:) requires unique normalized keys and non-blank strings. At least one stat is required."
      end
    end
  end
end
