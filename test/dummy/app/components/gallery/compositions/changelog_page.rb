module Gallery
  module Compositions
    class ChangelogPage < ScenarioPage
      private

      def render_scenario
        workspace_surface do
          render_header
          render_release_summary if featured_release
          render_changelog
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: changelog_title,
          description: state_description,
          id: "gallery-changelog-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(id: "gallery-changelog-header-actions", label: "Changelog navigation")
          ) do |actions|
            if state.in?(%w[archive empty])
              actions.button("Latest release", href: entry_path(entry, state: "latest"), icon: :arrow_left)
            else
              actions.button("Release archive", href: entry_path(entry, state: "archive"), icon: :history)
            end
          end
        end
      end

      def render_release_summary
        latest = featured_release

        render NitroKit::Card.new(id: "gallery-changelog-latest-card") do |card|
          card.title("#{latest.version} · #{release_title(latest)}", level: 2)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
                render NitroKit::Badge.new(
                  "Released #{latest.released_on.to_fs(:long)}",
                  color: :success,
                  id: "gallery-changelog-latest-status"
                )
              end
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
          title: state == "archive" ? "Release archive" : "Earlier releases",
          description: state == "archive" ? "Browse every published release and its change count." : "Review previous releases and the work included in each version.",
          id: "gallery-changelog-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-changelog-actions", label: "Release history actions")
          ) do |actions|
            actions.button("Subscribe to releases", href: "#release-feed")
          end

          if history_entries.empty?
            section.empty_state NitroKit::EmptyState.new(
              title: "No archived releases",
              description: "Published releases will appear here after the application records them.",
              variant: :borderless,
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
          history_entries.each do |release|
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

      def featured_release
        return if state.in?(%w[archive empty])

        entries.first
      end

      def history_entries
        featured_release ? entries.drop(1) : entries
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

      def section_title = "Product release history"
      def section_description = "Latest, archive, empty, long-content, and narrow documentation states."

      def state_description
        {
          "latest" => "See what changed in the newest release and find migration notes before upgrading.",
          "archive" => "Browse the complete release history, ordered from newest to oldest.",
          "empty" => "No releases have been archived yet. The latest release remains available.",
          "long" => "Review a release spanning typed sections for large, distributed application teams.",
          "mobile" => "Read the latest changes and earlier version summaries on a narrow screen."
        }.fetch(state)
      end
    end
  end
end
