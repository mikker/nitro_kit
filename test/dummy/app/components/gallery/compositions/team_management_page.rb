module Gallery
  module Compositions
    class TeamManagementPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::Request
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        render_composition_header

        render Section.new(
          slug: "team-management-screen",
          title: "Team members and invitations",
          description: "Inventory, search, invitation, access changes, removal, recovery, density, and mobile pressure."
        ) do
          render_example(
            slug: "team-management-#{state}",
            title: humanize_state(state),
            description: state_description,
            mode: :full_width
          ) do
            div(
              data: {
                gallery: "composition-surface",
                gallery_composition: "team-management",
                gallery_composition_state: state,
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-team-container") do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-team-stack") do
                  turbo_frame_tag("gallery-team-management-frame") { render_screen }
                end
              end
            end
          end
        end
      end

      def render_screen
        case state
        when "members", "dense", "mobile"
          render_team_inventory(table_members, pending_invitations)
        when "multiple-teams"
          render_multiple_teams
        when "search"
          render_search
        when "empty"
          render_empty
        when "invite", "invite-validation", "loading"
          render_invitation_form
        when "role-change"
          render_role_form
        when "last-owner-validation"
          render_last_owner_validation
        when "remove-confirmation"
          render_remove_confirmation
        when "removed"
          render_removed
        when "error"
          render_error
        end
      end

      def render_team_inventory(members, invitations)
        render NitroKit::Flex.new(
          dir: :col,
          gap: 6,
          align: :stretch,
          id: "gallery-team-inventory-stack"
        ) do
          render_member_section(members)
          render_pending_invitation_section(invitations)
        end
      end

      def render_member_section(members)
        render NitroKit::DataSection.new(
          title: state == "dense" ? "Large team inventory" : member_section_title,
          description: "#{members.length} current #{'membership'.pluralize(members.length)} with roles, join dates, and account actions.",
          id: "gallery-team-members-section"
        ) do |section|
          section.table NitroKit::Table.new(
            id: "gallery-team-members-table",
            table_aria: { label: "Workspace members" }
          ) do |table|
            render_member_table_content(table, members)
          end
        end
      end

      def render_pending_invitation_section(invitations)
        render NitroKit::DataSection.new(
          title: state == "search" ? "Pending invitation matches" : "Pending invitations",
          description: "Invitations remain separate from memberships until the intended recipient accepts.",
          id: "gallery-team-invitations-section"
        ) do |section|
          section.actions NitroKit::Button.new(
            "Invite teammate",
            id: "gallery-team-footer-invite",
            href: entry_path(entry, state: "invite"),
            variant: :primary
          )
          if invitations.empty?
            section.empty_state NitroKit::EmptyState.new(
              title: "No pending invitations match",
              description: "The current member search did not match an invited email address.",
              level: 3,
              id: "gallery-team-invitations-empty"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:mail_search)
            end
          else
            section.table NitroKit::Table.new(
              id: "gallery-team-invitations-table",
              table_aria: { label: "Pending team invitations" }
            ) do |table|
              table.caption("#{invitations.length} pending invitations")
              table.thead do
                table.tr do
                  table.th("Email")
                  table.th("Role")
                  table.th("Invited by")
                  table.th("Sent")
                  table.th("Expires")
                  table.th("Actions", align: :right)
                end
              end
              table.tbody do
                invitations.each do |invitation|
                  table.tr do
                    table.th(invitation.email, scope: :row)
                    table.td(invitation.role.to_s.humanize)
                    table.td(invitation.invited_by)
                    table.td(invitation.sent_at.to_fs(:short))
                    table.td(invitation.expires_on.to_fs(:long))
                    table.td(align: :right) do
                      render NitroKit::ButtonGroup.new(
                        label: "Actions for invitation to #{invitation.email}",
                        id: "gallery-team-invitation-#{invitation.id}-actions"
                      ) do |actions|
                        actions.button("Resend", href: "#resend-#{invitation.id}", size: :sm)
                        actions.button(
                          "Revoke",
                          href: "#revoke-#{invitation.id}",
                          size: :sm,
                          variant: :destructive
                        )
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_member_table_content(table, members)
        table.caption("#{members.length} workspace #{'member'.pluralize(members.length)}")
        table.thead do
          table.tr do
            table.th("Member")
            table.th("Role")
            table.th("Status")
            table.th("Joined")
            table.th("Actions", align: :right)
          end
        end
        table.tbody do
          members.each do |member|
            table.tr do
              table.th(scope: :row) do
                render NitroKit::Avatar.new(
                  alt: member.name,
                  fallback: initials(member.name),
                  size: :sm,
                  id: "gallery-team-member-#{member.id}-avatar"
                )
                strong { member.name }
                small { member.email }
              end
              table.td do
                render NitroKit::Badge.new(
                  member.role.to_s.humanize,
                  id: "gallery-team-member-#{member.id}-role",
                  variant: :outline,
                  color: member.role == :owner ? :info : :neutral,
                  size: :sm
                )
              end
              table.td do
                render NitroKit::Badge.new(
                  member.status.to_s.humanize,
                  id: "gallery-team-member-#{member.id}-status",
                  color: member_status_color(member.status),
                  size: :sm
                )
              end
              table.td(member.joined_on&.iso8601 || "Invitation pending")
              table.td(align: :right) { render_member_actions(member) }
            end
          end
        end
      end

      def render_member_actions(member)
        owner_validation_path = team_flow_path(state: "last-owner-validation", member_id: member.id)

        render NitroKit::ButtonGroup.new(
          id: "gallery-team-member-#{member.id}-actions",
          label: "Actions for #{member.name}"
        ) do |group|
          group.button(
            "Change role",
            id: "gallery-team-member-#{member.id}-change-role",
            href: member.role == :owner ? owner_validation_path : team_flow_path(state: "role-change", member_id: member.id),
            size: :sm
          )
          group.button(
            "Remove",
            id: "gallery-team-member-#{member.id}-remove",
            href: member.role == :owner ? owner_validation_path : team_flow_path(state: "remove-confirmation", member_id: member.id),
            size: :sm,
            variant: :destructive
          )
        end
      end

      def render_search
        render NitroKit::Flex.new(
          dir: :col,
          gap: 6,
          align: :stretch,
          id: "gallery-team-search-stack"
        ) do
          render NitroKit::SettingsSection.new(
            title: "Search the team",
            description: "Find current members and pending invitations by name or email address.",
            id: "gallery-team-search-section"
          ) do |section|
            section.form do
              form_with(
                scope: :team,
                url: entry_path(entry, state: "search"),
                method: :get,
                builder: NitroKit::FormBuilder,
                id: "gallery-team-search-form",
                data: {
                  turbo_frame: "gallery-team-management-frame",
                  turbo_action: "replace"
                }
              ) do |form|
                form.group do
                  form.field(
                    :query,
                    as: :search,
                    id: "gallery-team-search-query",
                    value: "Grace",
                    label: "Search members and invitations",
                    placeholder: "Name or email",
                    autocomplete: "off"
                  )
                  form.submit(
                    "Search",
                    id: "gallery-team-search-submit",
                    data: { turbo_submits_with: "Searching…" }
                  )
                end
              end
            end
          end

          render_team_inventory(
            current_members.select { |member| member.name.include?("Grace") },
            pending_invitations.select { |invitation| invitation.email.include?("Grace") }
          )
        end
      end

      def render_multiple_teams
        current_team = selected_team
        ada_membership = current_members.find { |membership| membership.id == "mem_ada" }

        render NitroKit::Flex.new(
          dir: :col,
          gap: 6,
          align: :stretch,
          id: "gallery-team-multiple-teams-stack"
        ) do
          render NitroKit::SettingsSection.new(
            title: "Team context",
            description: "Membership role and every mutation are scoped to the selected team.",
            id: "gallery-team-context-section"
          ) do |section|
            section.status NitroKit::Alert.new(id: "gallery-team-context-status", variant: :info) do |alert|
              alert.title("#{current_team.name} is selected")
              alert.description(
                "Ada Lovelace is #{ada_membership.role.to_s.humanize.downcase} here and has different roles in two other teams."
              )
            end
            section.form do
              form_with(
                scope: :team_context,
                url: entry_path(entry, state: "multiple-teams"),
                method: :get,
                builder: NitroKit::FormBuilder,
                id: "gallery-team-context-form",
                data: {
                  turbo_frame: "gallery-team-management-frame",
                  turbo_action: "replace"
                }
              ) do |form|
                form.group do
                  form.field(
                    :team_id,
                    as: :select,
                    label: "Current team",
                    value: current_team.id,
                    options: Gallery::Data.teams.map do |team|
                      [ "#{team.name} — #{team.role.to_s.humanize} — #{team.member_count} members", team.id ]
                    end
                  )
                  form.submit("Switch team", id: "gallery-team-context-submit")
                end
              end
            end
          end

          render_team_inventory(current_members, pending_invitations)
        end
      end

      def render_empty
        render NitroKit::DataSection.new(
          title: "Workspace members",
          description: "Invite collaborators when you are ready to share workspace access.",
          id: "gallery-team-empty-section"
        ) do |section|
          section.empty_state NitroKit::EmptyState.new(
            title: "No teammates yet",
            description: "Invite collaborators when you are ready to share workspace access.",
            level: 3,
            id: "gallery-team-empty"
          ) do |empty|
            empty.icon NitroKit::Icon.new(:users, id: "gallery-team-empty-icon")
            empty.action NitroKit::Button.new(
              "Invite first teammate",
              id: "gallery-team-empty-invite",
              href: entry_path(entry, state: "invite"),
              variant: :primary
            )
          end
        end
      end

      def render_invitation_form
        invitation = Gallery::FormExamples.team_invitation(state == "invite-validation" ? :invalid : :valid)
        disabled = state == "loading"

        render NitroKit::SettingsSection.new(
          title: "Invite a teammate",
          description: "Choose the access they need and add an optional note to the invitation email.",
          id: "gallery-team-invitation-section"
        ) do |section|
          if state == "invite-validation"
            section.status NitroKit::Alert.new(id: "gallery-team-invitation-error", variant: :error) do |alert|
              alert.title("The invitation could not be sent")
              alert.description("Correct the email, role, and message fields below.")
            end
          end
          section.form do
            form_with(
              model: invitation,
              url: "#team-invitation",
              builder: NitroKit::FormBuilder,
              id: "gallery-team-invitation-form",
              data: { turbo_frame: "gallery-team-management-frame" }
            ) do |form|
              form.group do
                form.field(
                  :email,
                  as: :email,
                  label: "Email address",
                  autocomplete: "email",
                  required: true,
                  disabled:
                )
                form.field(
                  :role,
                  as: :select,
                  label: "Workspace role",
                  options: [ [ "Administrator", "admin" ], [ "Member", "member" ], [ "Viewer", "viewer" ] ],
                  required: true,
                  disabled:
                )
                form.field(
                  :message,
                  as: :textarea,
                  label: "Invitation message",
                  description: "Optional. Keep the message below 240 characters.",
                  disabled:
                )
                form.submit(
                  disabled ? "Sending invitation…" : "Send invitation",
                  id: "gallery-team-invitation-submit",
                  disabled:,
                  data: { turbo_submits_with: "Sending invitation…" }
                )
              end
            end
          end
        end
      end

      def render_role_form
        membership = selected_membership(default_id: "mem_grace")
        action = Gallery::Forms::TeamMemberAction.new(
          team_id: selected_team.id,
          action: "change_role",
          member_id: membership.id,
          role: "viewer"
        )

        render NitroKit::SettingsSection.new(
          title: "Change member role",
          description: "Choose the access this member should have across the selected workspace.",
          id: "gallery-team-role-section"
        ) do |section|
          section.status NitroKit::Alert.new(id: "gallery-team-role-context") do |alert|
            alert.title("Changing #{membership.name}")
            alert.description("Role changes take effect immediately and are recorded in the audit log.")
          end
          section.form do
            form_with(
              model: action,
              url: "#team-role",
              builder: NitroKit::FormBuilder,
              id: "gallery-team-role-form",
              data: { turbo_frame: "gallery-team-management-frame" }
              ) do |form|
                form.group do
                  form.hidden_field(:action)
                  form.hidden_field(:team_id)
                  form.hidden_field(:member_id)
                form.field(
                  :role,
                  as: :select,
                  label: "New role",
                  options: Gallery::Forms::TeamMemberAction::ROLES.map { |role| [ role.humanize, role ] },
                  required: true
                )
                form.submit(
                  "Update role",
                  id: "gallery-team-role-submit",
                  data: { turbo_submits_with: "Updating role…" }
                )
              end
            end
          end
        end
      end

      def render_last_owner_validation
        membership = selected_membership(default_id: "mem_ada")
        action = Gallery::Forms::TeamMemberAction.new(
          team_id: selected_team.id,
          action: "change_role",
          member_id: membership.id,
          role: "member"
        )
        action.validate

        render NitroKit::SettingsSection.new(
          title: "Keep an owner",
          description: "The domain model rejects role changes and removals that would leave a team ownerless.",
          id: "gallery-team-last-owner-section"
        ) do |section|
          section.status NitroKit::Alert.new(
            id: "gallery-team-last-owner-error",
            variant: :error,
            live: :assertive
          ) do |alert|
            alert.title("#{membership.name} is the last owner")
            alert.description("The server rejected this change. Promote another member before changing #{membership.name}'s role.")
          end
          section.form do
            form_with(
              model: action,
              url: "#last-owner-validation",
              builder: NitroKit::FormBuilder,
              id: "gallery-team-last-owner-form",
              data: { turbo_frame: "gallery-team-management-frame" }
              ) do |form|
                form.group do
                  form.hidden_field(:action)
                  form.hidden_field(:team_id)
                  form.hidden_field(:member_id)
                form.field(
                  :role,
                  as: :select,
                  label: "New role for #{membership.name}",
                  options: Gallery::Forms::TeamMemberAction::ROLES.map { |role| [ role.humanize, role ] },
                  required: true
                )
                form.submit("Change role", id: "gallery-team-last-owner-submit")
              end
            end
          end
        end
      end

      def render_remove_confirmation
        membership = selected_membership(default_id: "mem_grace")
        action = Gallery::Forms::TeamMemberAction.new(
          team_id: selected_team.id,
          action: "remove",
          member_id: membership.id,
          confirmation: membership.email
        )

        render NitroKit::DangerZone.new(
          title: "Remove workspace access",
          description: "#{membership.name} will immediately lose access to every project and all active sessions will be revoked.",
          id: "gallery-team-remove-zone"
        ) do |zone|
          zone.confirmation do
            render NitroKit::Dialog.new(id: "gallery-team-remove-dialog") do |dialog|
              dialog.panel(
                title: "Remove #{membership.name}?",
                description: "#{membership.name} will immediately lose access to every project in this workspace.",
                nonmodal: true
              ) do
                form_with(
                  model: action,
                  url: "#team-remove",
                  builder: NitroKit::FormBuilder,
                  id: "gallery-team-remove-form",
                  data: { turbo_frame: "gallery-team-management-frame" }
                ) do |form|
                  form.group do
                    form.hidden_field(:action)
                    form.hidden_field(:team_id)
                    form.hidden_field(:member_id)
                    form.field(
                      :confirmation,
                      as: :email,
                      label: "Type #{membership.email} to confirm",
                      autocomplete: "off",
                      required: true
                    )
                    form.submit(
                      "Remove member",
                      id: "gallery-team-remove-submit",
                      variant: :destructive,
                      data: { turbo_submits_with: "Removing member…" }
                    )
                    dialog.close_button(label: "Keep team member")
                  end
                end
              end
            end
          end
          zone.escape NitroKit::Button.new(
            "Keep team member",
            id: "gallery-team-remove-escape",
            href: team_flow_path(state: "members")
          )
        end
      end

      def render_removed
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-team-removed-stack") do
          render NitroKit::Alert.new(id: "gallery-team-removed", variant: :success) do |alert|
            alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-team-removed-icon"))
            alert.title("Grace Hopper was removed")
            alert.description("Her active sessions were revoked and the change was written to the audit log.")
          end
          render_back_to_members
        end
      end

      def render_error
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-team-error-stack") do
          render NitroKit::Alert.new(id: "gallery-team-error", variant: :error) do |alert|
            alert.icon(NitroKit::Icon.new(:circle_x, id: "gallery-team-error-icon"))
            alert.title("The team could not be updated")
            alert.description("No access changed. Refresh the member list before trying the operation again.")
          end
          render_back_to_members
        end
      end

      def render_back_to_members
        render NitroKit::Button.new(
          "Back to members",
          id: "gallery-team-footer-members",
          href: team_flow_path(state: "members")
        )
      end

      def table_members
        Gallery::Data.memberships(team_id: selected_team.id, dense: state == "dense")
      end

      def current_members
        Gallery::Data.memberships(team_id: selected_team.id)
      end

      def pending_invitations
        Gallery::Data.pending_invitations(team_id: selected_team.id)
      end

      def selected_team
        team_id = request.query_parameters.dig("team_context", "team_id")
        Gallery::Data.team(team_id) || Gallery::Data.current_team
      end

      def selected_membership(default_id:)
        member_id = request.query_parameters["member_id"].presence || default_id
        current_members.find { |membership| membership.id == member_id } || current_members.first
      end

      def team_flow_path(state:, member_id: request.query_parameters["member_id"])
        gallery_composition_path(
          slug: entry.slug,
          state:,
          team_context: { team_id: selected_team.id },
          member_id:
        )
      end

      def member_section_title
        state == "search" ? "Member matches" : "Workspace members"
      end

      def initials(name)
        name.split.map(&:first).first(2).join
      end

      def member_status_color(status)
        { active: :success, invited: :info, suspended: :warning }.fetch(status)
      end

      def state_description
        {
          "members" => "Current memberships and pending invitations use separately labelled data tables.",
          "multiple-teams" => "A deterministic team selector keeps role and membership policy scoped to the current team.",
          "search" => "A SettingsSection GET form and deterministic member and invitation results stay in one Turbo frame.",
          "empty" => "The absence of members leaves one clear invitation action.",
          "invite" => "A real invitation model collects email, role, and optional context.",
          "invite-validation" => "Active Model errors cover malformed email, unsupported role, and long copy.",
          "loading" => "Invitation controls and submission are disabled while Turbo processes.",
          "role-change" => "A role update names the member and warns about immediate access changes.",
          "last-owner-validation" => "A failed server validation preserves the attempted demotion and explains last-owner policy.",
          "remove-confirmation" => "A native open dialog requires the member email before destructive submission.",
          "removed" => "Completion confirms session revocation and audit history.",
          "error" => "Failure copy confirms that no access changed and gives a safe retry path.",
          "dense" => "Eight deterministic memberships pressure row actions and long account data.",
          "mobile" => "The member inventory remains semantic inside a narrow overflow surface."
        }.fetch(state)
      end
    end
  end
end
