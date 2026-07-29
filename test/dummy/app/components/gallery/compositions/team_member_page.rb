module Gallery
  module Compositions
    class TeamMemberPage < ExpandedPage
      private

      def render_state
        if member
          render_member_summary
          render_member_stats
          render_member_activity
        else
          render_missing_member
        end
      end

      def render_member_summary
        render NitroKit::Card.new(id: "gallery-team-member-summary") do |card|
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Toolbar.new(id: "gallery-team-member-identity") do |toolbar|
                toolbar.leading do
                  render NitroKit::Avatar.new(
                    src: member.avatar_url,
                    alt: member.name,
                    fallback: initials(member.name),
                    size: :lg,
                    id: "gallery-team-member-avatar"
                  )
                  h2 { member_name }
                  render NitroKit::Badge.new(
                    member.status.to_s.humanize,
                    id: "gallery-team-member-status",
                    color: member_status_color(member.status)
                  )
                end
                toolbar.trailing do
                  render NitroKit::Button.new(
                    "Edit role",
                    href: "#edit-member-role",
                    disabled: !policy.manage_team?
                  )
                  render NitroKit::Button.new(
                    "Remove member",
                    href: "#remove-member",
                    variant: :destructive,
                    disabled: !policy.remove_member?(member)
                  )
                end
              end
              render NitroKit::DetailsTable.new(
                member,
                label: "Team member metadata",
                empty_text: "Invitation pending",
                id: "gallery-team-member-metadata"
              ) do |details|
                details.field(:email)
                details.field(:role) do |role|
                  render NitroKit::Badge.new(
                    role.to_s.humanize,
                    color: role == :owner ? :info : :neutral,
                    size: :sm
                  )
                end
                details.field(:joined_on, label: "Joined")
                details.field(
                  :organization,
                  value: Gallery::ExpandedData.organization.name
                )
              end
            end
          end
        end
      end

      def render_member_stats
        invited = member.status == :invited

        render NitroKit::StatGrid.new(id: "gallery-team-member-stats") do |stats|
          stats.stat(key: :sessions, label: "Active sessions", value: invited ? "0" : "2", detail: "Last verified 8 minutes ago")
          stats.stat(key: :resources, label: "Resource access", value: invited ? "0" : "18", detail: "Across four teams")
          stats.stat(key: :events, label: "Events this month", value: invited ? "0" : "47", detail: "No unresolved policy alerts")
        end
      end

      def render_member_activity
        events = member_events

        render NitroKit::DataSection.new(
          title: "Recent member activity",
          description: "Events remain tied to the caller-owned member identifier.",
          id: "gallery-team-member-activity"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Member activity actions")) do |actions|
            actions.button("View all activity", href: team_activity_path)
          end

          if events.empty?
            section.empty_state(
              NitroKit::EmptyState.new(
                title: "No activity recorded",
                description: member.status == :invited ? "Activity begins after the invitation is accepted." : "No events match this member.",
                level: 3,
                id: "gallery-team-member-activity-empty"
              )
            ) do |empty|
              empty.icon(NitroKit::Icon.new("history"))
            end
          else
            section.table(NitroKit::Table.new(id: "gallery-team-member-activity-table")) do |table|
              table.caption("Recent activity for #{member.name}")
              table.thead do
                table.tr do
                  table.th("Activity")
                  table.th("Outcome")
                  table.th("Occurred") unless state == "mobile"
                end
              end
              table.tbody do
                events.each do |event|
                  table.tr do
                    table.th("#{event.action}: #{event.subject}", scope: :row)
                    table.td do
                      render NitroKit::Badge.new(
                        event.outcome.to_s.humanize,
                        color: outcome_color(event.outcome),
                        size: :sm
                      )
                    end
                    table.td(event.occurred_at.to_fs(:long)) unless state == "mobile"
                  end
                end
              end
            end
          end
        end
      end

      def render_missing_member
        render NitroKit::Alert.new(id: "gallery-team-member-error", variant: :error) do |alert|
          alert.title(state == "error" ? "Member lookup failed" : "Member not found")
          alert.description(
            state == "error" ? "The directory service did not return a verified member record." : "This member may have left the organization or the link may be outdated."
          )
        end
        render NitroKit::DataSection.new(
          title: "Member detail",
          description: "A missing record remains an explicit resource state.",
          id: "gallery-team-member-missing"
        ) do |section|
          section.empty_state(
            NitroKit::EmptyState.new(
              title: state == "error" ? "Member detail is temporarily unavailable" : "No member matches this link",
              description: "Return to team activity or search the organization directory.",
              level: 3,
              id: "gallery-team-member-empty"
            )
          ) do |empty|
            empty.icon(NitroKit::Icon.new(state == "error" ? "triangle-alert" : "user-round-search"))
            empty.action(NitroKit::Button.new("View team activity", href: team_activity_path, variant: :primary))
          end
        end
      end

      def member
        @member ||= case state
        when "invited"
          Gallery::Data.members.find { |candidate| candidate.status == :invited }
        when "suspended"
          Gallery::Data.dense_members.find { |candidate| candidate.status == :suspended }
        when "empty", "error"
          nil
        else
          Gallery::Data.members.find { |candidate| candidate.id == "mem_grace" }
        end
      end

      def member_events
        events = Gallery::ExpandedData.team_events.select { |event| event.member_id == member.id }
        state == "activity" ? events : events.first(1)
      end

      def member_name
        return member.name unless state == "long"

        "Rear Admiral Grace Brewster Murray Hopper — International Research and Production Administration"
      end

      def member_status_color(status)
        { active: :success, invited: :info, suspended: :danger }.fetch(status, :neutral)
      end

      def policy
        Gallery::ExpandedAccessPolicy.new(role: state == "suspended" ? :viewer : :administrator)
      end

      def initials(name)
        name.split.filter_map { |part| part[0] }.first(2).join
      end

      def team_activity_path
        gallery_composition_path(slug: "team-activity", state: "recent")
      end

      def screen_title
        member ? member_name : "Team member"
      end

      def header_actions(actions)
        actions.button("Team activity", href: team_activity_path)
        actions.button("Invite member", href: "#invite-member", variant: :primary)
      end

      def state_description
        {
          "active" => "Active member identity, authorization, usage metrics, and recent events.",
          "invited" => "A pending invitation has identity and role context but no activity yet.",
          "suspended" => "A suspended member remains inspectable while a viewer policy disables mutation.",
          "activity" => "A member detail focused on the complete recent history for one member identifier.",
          "empty" => "An outdated route resolves to an explicit missing-member state.",
          "error" => "A directory failure separates unavailable data from a confirmed missing record.",
          "long" => "A long professional identity pressures the same summary and action structures.",
          "mobile" => "Caller-owned compact table columns complement accepted narrow layout behavior."
        }.fetch(state)
      end
    end
  end
end
