module Gallery
  module Compositions
    class ChangelogPage < ScenarioPage
      private

      def render_scenario
        workspace_surface do
          render_header
          render_release_summary if entries.any?
          render_changelog
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: changelog_title,
          eyebrow: "Nitro Kit releases",
          description: state_description,
          id: "gallery-changelog-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(id: "gallery-changelog-header-actions", label: "Changelog navigation")
          ) do |actions|
            actions.button("Latest release", href: entry_path(entry, state: "latest"), variant: :primary)
            actions.button("Release archive", href: entry_path(entry, state: "archive"))
          end
        end
      end

      def render_release_summary
        latest = entries.first

        render NitroKit::Card.new(id: "gallery-changelog-latest-card") do |card|
          card.title("#{latest.version} · #{release_title(latest)}", level: 2)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Badge.new(
                "Released #{latest.released_on.to_fs(:long)}",
                color: :success,
                id: "gallery-changelog-latest-status"
              )
              render NitroKit::Typeset.new(id: "gallery-changelog-latest-prose") do
                p { latest.summary }
                ul do
                  latest.changes.each { |change| li { change } }
                end
              end
            end
          end
          card.footer do
            render NitroKit::Button.new(
              "Read migration notes",
              href: "#migration-#{latest.version}",
              id: "gallery-changelog-migration-notes"
            )
          end
        end
      end

      def render_changelog
        render NitroKit::DataSection.new(
          title: state == "archive" ? "Release archive" : "Release history",
          description: "Version identity, release dates, and summaries are caller-owned documentation records.",
          id: "gallery-changelog-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-changelog-actions", label: "Release history actions")
          ) do |actions|
            actions.button("Subscribe to releases", href: "#release-feed")
          end

          if entries.empty?
            section.empty_state NitroKit::EmptyState.new(
              title: "No archived releases",
              description: "Published releases will appear here after the application records them.",
              level: 3,
              id: "gallery-changelog-empty"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:history, id: "gallery-changelog-empty-icon")
              empty.action NitroKit::Button.new("Return to latest release", href: entry_path(entry, state: "latest"))
            end
          else
            section.table NitroKit::Table.new(id: "gallery-changelog-table") do |table|
              populate_changelog_table(table)
            end
          end
        end
      end

      def populate_changelog_table(table)
        table.caption("Published Nitro Kit releases")
        table.thead do
          table.tr do
            table.th("Version")
            table.th("Released") unless state == "mobile"
            table.th("Summary")
            table.th("Changes", align: :right) unless state == "mobile"
          end
        end
        table.tbody do
          entries.each_with_index do |release, index|
            table.tr do
              table.th(release.version, scope: :row)
              table.td(release.released_on.to_fs(:long)) unless state == "mobile"
              table.td("#{release_title(release)} — #{release.summary}")
              table.td(release.changes.size.to_s, align: :right) unless state == "mobile"
            end
          end
        end
      end

      def entries
        @entries ||= case state
        when "empty"
          []
        when "archive"
          Gallery::OperationalData.changelog_entries * 2
        when "mobile"
          Gallery::OperationalData.changelog_entries.first(2)
        else
          Gallery::OperationalData.changelog_entries
        end
      end

      def release_title(release)
        return release.title unless state == "long" && release == entries.first

        "Typed application sections for International Research, Production, Reliability Engineering, and Customer Operations"
      end

      def changelog_title
        return "Nitro Kit release archive" if state == "archive"
        return "Nitro Kit release notes for application teams operating regulated international workspaces" if state == "long"

        "Nitro Kit changelog"
      end

      def composition_label = "Changelog"
      def section_title = "Product release history"
      def section_description = "Latest, archive, empty, long-content, and narrow documentation states."

      def state_description
        {
          "latest" => "The newest version, changes, migration route, and release history remain explicit.",
          "archive" => "Repeated deterministic release records pressure a complete historical table.",
          "empty" => "An unpublished archive distinguishes no records from a loading or service error.",
          "long" => "Long release titles and summaries wrap without truncation or custom styling.",
          "mobile" => "Caller-owned compact release columns complement the narrow composition surface."
        }.fetch(state)
      end
    end
  end
end
