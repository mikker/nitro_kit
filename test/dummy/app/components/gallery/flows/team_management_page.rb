module Gallery
  module Flows
    class TeamManagementPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        header(data: { gallery: "flow-header" }) do
          p(data: { gallery: "eyebrow" }) { "Team operations flow" }
          h1 { entry.title }
          p { entry.description }
          state_navigation
        end

        render Section.new(
          slug: "team-management-screen",
          title: "Team members and invitations",
          description: "Inventory, search, invitation, access changes, removal, recovery, density, and mobile pressure."
        ) do
          render_example(
            slug: "team-management-#{state}",
            title: state.to_s.humanize,
            description: state_description,
            mode: :full_width
          ) do
            div(
              data: {
                gallery: "flow-surface",
                gallery_flow: "team-management",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-team-container") do
                render NitroKit::VStack.new(gap: :lg, align: :stretch, id: "gallery-team-stack") do
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
          render_member_section(table_members)
        when "search"
          render_search
        when "empty"
          render_empty
        when "invite", "invite-validation", "loading"
          render_invitation_form
        when "role-change"
          render_role_form
        when "remove-confirmation"
          render_remove_confirmation
        when "removed"
          render_removed
        when "error"
          render_error
        end
      end

      def render_member_section(members)
        render NitroKit::DataSection.new(
          title: state == "dense" ? "Large team inventory" : "Workspace members",
          description: "Member roles, invitation state, join dates, and account actions.",
          id: "gallery-team-members-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-team-directory-actions", label: "Team directory actions")
          ) do |group|
            group.button(
              "Invite teammate",
              id: "gallery-team-footer-invite",
              href: entry_path(entry, state: "invite"),
              variant: :primary
            )
          end
          section.table NitroKit::Table.new(
            id: "gallery-team-members-table",
            table_aria: { label: "Workspace members" }
          ) do |table|
            render_member_table_content(table, members)
          end
        end
      end

      def render_member_table_content(table, members)
          table.caption("#{members.length} workspace members")
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
        render NitroKit::ButtonGroup.new(
          id: "gallery-team-member-#{member.id}-actions",
          label: "Actions for #{member.name}"
        ) do |group|
          group.button(
            "Change role",
            id: "gallery-team-member-#{member.id}-change-role",
            href: entry_path(entry, state: "role-change"),
            size: :sm,
            variant: :ghost,
            disabled: member.role == :owner
          )
          group.button(
            "Remove",
            id: "gallery-team-member-#{member.id}-remove",
            href: entry_path(entry, state: "remove-confirmation"),
            size: :sm,
            variant: :destructive,
            disabled: member.role == :owner
          )
        end
      end

      def render_search
        form(
          id: "gallery-team-search-form",
          action: entry_path(entry, state: "search"),
          method: :get,
          data: { turbo_frame: "gallery-team-management-frame" }
        ) do
          render NitroKit::Field.new(
            nil,
            :query,
            as: :search,
            id: "gallery-team-search-query",
            name: "team[query]",
            value: "Grace",
            label: "Search members",
            placeholder: "Name or email",
            autocomplete: "off"
          )
          render NitroKit::Button.new(
            "Search",
            id: "gallery-team-search-submit",
            type: :submit,
            variant: :primary,
            data: { turbo_submits_with: "Searching…" }
          )
        end
        render NitroKit::DataSection.new(
          title: "Search results",
          description: "Members matching the current name or email query.",
          id: "gallery-team-search-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-team-search-actions", label: "Team search actions")
          ) do |group|
            group.button(
              "Invite teammate",
              id: "gallery-team-footer-invite",
              href: entry_path(entry, state: "invite"),
              variant: :primary
            )
          end
          section.table NitroKit::Table.new(
            id: "gallery-team-members-table",
            table_aria: { label: "Workspace members" }
          ) do |table|
            render_member_table_content(
              table,
              Gallery::Data.members.select { |member| member.name.include?("Grace") }
            )
          end
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

        render NitroKit::FormSection.new(
          title: "Invitation details",
          description: "The application owns the invitation model, role policy, route, and Turbo frame.",
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

      def render_role_form
        action = Gallery::OperationsFormExamples.team_member_action(:role_valid)

        render NitroKit::FormSection.new(
          title: "Role assignment",
          description: "The submitted member ID and allowed roles remain application policy.",
          id: "gallery-team-role-section"
        ) do |section|
          section.status NitroKit::Alert.new(id: "gallery-team-role-context") do |alert|
            alert.title("Changing Grace Hopper")
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
              form.hidden_field(:action)
              form.hidden_field(:member_id)
              form.field(
                :role,
                as: :select,
                label: "New role",
                options: [ [ "Administrator", "admin" ], [ "Member", "member" ], [ "Viewer", "viewer" ] ],
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

      def render_remove_confirmation
        action = Gallery::OperationsFormExamples.team_member_action(:remove_valid)

        render NitroKit::DangerZone.new(
          title: "Remove workspace access",
          description: "Grace will immediately lose access to every project and all active sessions will be revoked.",
          id: "gallery-team-remove-zone"
        ) do |zone|
          zone.confirmation do
            render NitroKit::Dialog.new(id: "gallery-team-remove-dialog") do |dialog|
              dialog.dialog(
                title: "Remove Grace Hopper?",
                description: "Grace will immediately lose access to every project in this workspace.",
                open: true
              ) do
                form_with(
                  model: action,
                  url: "#team-remove",
                  builder: NitroKit::FormBuilder,
                  id: "gallery-team-remove-form",
                  data: { turbo_frame: "gallery-team-management-frame" }
                ) do |form|
                  form.hidden_field(:action)
                  form.hidden_field(:member_id)
                  form.field(
                    :confirmation,
                    as: :email,
                    label: "Type grace@example.test to confirm",
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
          zone.escape NitroKit::Button.new(
            "Keep team member",
            id: "gallery-team-remove-escape",
            href: entry_path(entry, state: "members"),
            variant: :ghost
          )
        end
      end

      def render_removed
        render NitroKit::VStack.new(gap: :md, align: :stretch, id: "gallery-team-removed-stack") do
          render NitroKit::Alert.new(id: "gallery-team-removed", variant: :success) do |alert|
            alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-team-removed-icon"))
            alert.title("Grace Hopper was removed")
            alert.description("Her active sessions were revoked and the change was written to the audit log.")
          end
          render_back_to_members
        end
      end

      def render_error
        render NitroKit::VStack.new(gap: :md, align: :stretch, id: "gallery-team-error-stack") do
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
          href: entry_path(entry, state: "members"),
          variant: :ghost
        )
      end

      def table_members
        state == "dense" ? Gallery::Data.dense_members : Gallery::Data.members
      end

      def initials(name)
        name.split.map(&:first).first(2).join
      end

      def member_status_color(status)
        { active: :success, invited: :info, suspended: :warning }.fetch(status)
      end

      def state_description
        {
          "members" => "A semantic member inventory with role, status, dates, and labelled actions.",
          "search" => "A GET search form and deterministic filtered result stay in one Turbo frame.",
          "empty" => "The absence of members leaves one clear invitation action.",
          "invite" => "A real invitation model collects email, role, and optional context.",
          "invite-validation" => "Active Model errors cover malformed email, unsupported role, and long copy.",
          "loading" => "Invitation controls and submission are disabled while Turbo processes.",
          "role-change" => "A role update names the member and warns about immediate access changes.",
          "remove-confirmation" => "A native open dialog requires the member email before destructive submission.",
          "removed" => "Completion confirms session revocation and audit history.",
          "error" => "Failure copy confirms that no access changed and gives a safe retry path.",
          "dense" => "Nine deterministic members pressure row actions and long account data.",
          "mobile" => "The member inventory remains semantic inside a narrow overflow surface."
        }.fetch(state)
      end

      def state_navigation
        nav(aria: { label: "Team management states" }, data: { gallery: "flow-states" }) do
          entry.states.each do |name|
            a(href: entry_path(entry, state: name), aria: { current: state == name ? "page" : nil }) do
              name.humanize
            end
          end
        end
      end
    end
  end
end
