module Gallery
  module Compositions
    class UsersPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      BulkOperation = ::Data.define(:operation, :performed_by, :audit_records)

      USERS = (
        Gallery::Data.members + [
          Gallery::Data::Member.new(
            id: "mem_dorothy",
            name: "Dorothy Vaughan",
            email: "dorothy.vaughan@example.test",
            role: :admin,
            status: :active,
            avatar_url: nil,
            joined_on: Date.new(2025, 1, 8)
          ),
          Gallery::Data::Member.new(
            id: "mem_margaret",
            name: "Margaret Hamilton",
            email: "margaret.hamilton+apollo-guidance-software@example.test",
            role: :member,
            status: :active,
            avatar_url: nil,
            joined_on: Date.new(2025, 4, 19)
          ),
          Gallery::Data::Member.new(
            id: "mem_annie",
            name: "Annie Easley",
            email: "annie.easley@example.test",
            role: :viewer,
            status: :suspended,
            avatar_url: nil,
            joined_on: Date.new(2025, 9, 30)
          ),
          Gallery::Data::Member.new(
            id: "mem_mary",
            name: "Mary Jackson",
            email: "mary.jackson@example.test",
            role: :member,
            status: :active,
            avatar_url: nil,
            joined_on: Date.new(2026, 2, 14)
          ),
          Gallery::Data::Member.new(
            id: "mem_chien",
            name: "Chien-Shiung Wu",
            email: "chien-shiung.wu+experimental-physics@example.test",
            role: :viewer,
            status: :invited,
            avatar_url: nil,
            joined_on: nil
          )
        ]
      ).freeze

      private

      def page_template
        render_composition_header(eyebrow: "Users")

        render Section.new(
          slug: "users-screen",
          title: "Workspace users",
          description: "Paginated index and search, identity detail, empty, loading, failure, bulk action, outcomes, and mobile pressure."
        ) do
          render_example(
            slug: "users-#{state}",
            title: state.humanize,
            description: state_description,
            mode: :full_width
          ) do
            div(
              data: {
                gallery: "composition-surface",
                gallery_composition: "users",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-users-container") do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-users-stack") do
                  turbo_frame_tag("gallery-users-frame") { render_screen }
                end
              end
            end
          end
        end
      end

      def render_screen
        case state
        when "index"
          render_index
        when "detail"
          render_detail
        when "search"
          render_search
        when "empty"
          render_empty
        when "loading"
          render_loading
        when "error"
          render_error
        when "bulk"
          render_bulk
        when "bulk-confirmation"
          render_bulk_confirmation
        when "bulk-complete"
          render_bulk_complete
        when "mobile"
          render_mobile
        end
      end

      def render_index
        render NitroKit::Badge.new("128 total", id: "gallery-users-count", color: :info, size: :sm)
        render NitroKit::DataSection.new(
          title: "Members of Analytical Engines — Research and Production",
          description: "Workspace identities, access state, and membership history.",
          id: "gallery-users-index-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-users-index-actions", label: "User directory actions")
          ) do |group|
              group.button(
                "Invite user",
                id: "gallery-users-invite",
                href: "#invite-user",
                variant: :primary
              )
              group.button(
                "Bulk actions",
                id: "gallery-users-bulk-link",
                href: entry_path(entry, state: "bulk")
              )
          end
          section.table NitroKit::Table.new(id: "gallery-users-index-table") do |table|
            render_users_table_content(table, USERS, id: "gallery-users-index-table", caption: "All workspace users")
          end
        end
        render_index_pagination
      end

      def render_detail
        user = USERS.fetch(1)

        render NitroKit::Card.new(id: "gallery-users-detail-card") do |card|
          card.title(user.name, level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Avatar.new(
                src: user.avatar_url,
                alt: user.name,
                fallback: initials(user.name),
                size: :lg,
                id: "gallery-users-detail-avatar"
              )
              render NitroKit::Badge.new("Active", id: "gallery-users-detail-status", color: :success)
              render NitroKit::DetailsTable.new(
                user,
                data: { gallery: "user-detail-metadata" }
              ) do |details|
                details.field(:email)
                details.field(:role) { |role| plain role.to_s.humanize }
                details.field(:joined_on, label: "Joined") { |date| plain date.to_fs(:long) }
                details.field(:last_sign_in, value: "July 13, 2026 at 07:58 UTC from 198.51.100.17")
                details.field(:multi_factor_authentication, value: "Security key and recovery codes")
              end
              render_activity_table(user)
            end
          end
          card.divider
          card.footer do
            render NitroKit::ButtonGroup.new(id: "gallery-users-detail-actions", label: "Actions for #{user.name}") do |group|
              group.button("Edit role", id: "gallery-users-edit-role", href: "#edit-role", variant: :primary)
              group.button("Reset sessions", id: "gallery-users-reset-sessions", href: "#reset-sessions")
              group.button("Suspend user", id: "gallery-users-suspend", href: "#suspend", variant: :destructive)
            end
          end
        end
      end

      def render_search
        search = Gallery::Forms::UserSearch.new(query: "a", status: "active")
        results = USERS.select { |user| user.status == :active }

        render_search_form(search)
        render NitroKit::DataSection.new(
          title: "Search results",
          description: "Active users matching the current name, email, and status filters.",
          id: "gallery-users-search-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-users-search-actions", label: "User search actions")
          ) do |group|
            group.button(
              "Clear search",
              id: "gallery-users-clear-search",
              href: entry_path(entry, state: "index")
            )
          end
          section.table NitroKit::Table.new(id: "gallery-users-search-results") do |table|
            render_users_table_content(
              table,
              results,
              id: "gallery-users-search-results",
              caption: "Active user search results, page 3"
            )
          end
        end
        render_search_pagination
      end

      def render_empty
        search = Gallery::Forms::UserSearch.new(query: "unfindable@example.test", status: "active")

        render_search_form(search)
        render NitroKit::DataSection.new(
          title: "Search results",
          description: "The current filters did not match a workspace identity.",
          id: "gallery-users-empty-section"
        ) do |section|
          section.empty_state NitroKit::EmptyState.new(
            title: "No users match this search",
            description: "Try a shorter name, the exact invitation email, or include suspended and invited users.",
            level: 3,
            id: "gallery-users-empty"
          ) do |empty|
            empty.icon NitroKit::Icon.new(:search_x, id: "gallery-users-empty-icon")
            empty.action NitroKit::Button.new(
              "Reset filters",
              id: "gallery-users-empty-reset",
              href: entry_path(entry, state: "index"),
              variant: :primary
            )
          end
        end
      end

      def render_loading
        search = Gallery::Forms::UserSearch.new(query: "research", status: "all")

        div(aria: { busy: "true", live: "polite" }, data: { gallery: "users-loading-region" }) do
          render_search_form(search, disabled: true)
          render NitroKit::DataSection.new(
            title: "Searching users…",
            description: "Checking names, email addresses, roles, and invitation status…",
            id: "gallery-users-loading-section"
          ) do |section|
            section.actions(
              NitroKit::ButtonGroup.new(id: "gallery-users-loading-actions", label: "User search status")
            ) do |group|
              group.button(
                "Search in progress…",
                id: "gallery-users-loading-action",
                disabled: true,
                variant: :primary
              )
            end
            section.table NitroKit::Table.new(id: "gallery-users-loading-table") do |table|
              table.caption("User search is loading")
              table.thead do
                table.tr do
                  table.th("User")
                  table.th("Role")
                  table.th("Status")
                end
              end
              table.tbody do
                3.times do |index|
                  table.tr do
                    table.th("Loading user #{index + 1}", scope: :row)
                    table.td("—")
                    table.td("—")
                  end
                end
              end
            end
          end
        end
      end

      def render_error
        render NitroKit::Card.new(id: "gallery-users-error-card") do |card|
          card.title("Users could not be loaded", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Alert.new(id: "gallery-users-error", variant: :error) do |alert|
                alert.icon(NitroKit::Icon.new(:circle_x, id: "gallery-users-error-icon"))
                alert.title("The directory service did not respond")
                alert.description("No user data was changed. Retry now or return to workspace settings.")
              end
              p { "Reference: users_read_timeout_2026_07_13_0917" }
            end
          end
          card.divider
          card.footer do
            render NitroKit::ButtonGroup.new(id: "gallery-users-error-actions", label: "Directory recovery actions") do |group|
              group.button("Retry", id: "gallery-users-retry", href: entry_path(entry, state: "index"), variant: :primary)
              group.button("Workspace settings", id: "gallery-users-settings", href: "#workspace-settings")
            end
          end
        end
      end

      def render_bulk
        bulk_action = Gallery::Forms::BulkUserAction.new(
          member_ids: %w[mem_katherine mem_chien],
          action: "remind"
        )

        render NitroKit::SettingsSection.new(
          title: "Bulk user actions",
          description: "Select users, choose one action, and review the affected records before applying it.",
          id: "gallery-users-bulk-section"
        ) do |section|
          section.form do
            p { "Select users, choose one action, and review the affected records before applying it." }
            form_with(
              model: bulk_action,
              url: "#bulk-users",
              builder: NitroKit::FormBuilder,
              id: "gallery-users-bulk-form",
              data: { turbo_frame: "gallery-users-frame" }
            ) do |form|
              form.group do
                render NitroKit::CheckboxGroup.new(
                  id: "gallery-users-bulk-selection",
                  legend: "Users to update",
                  description: "Workspace owners cannot be suspended or removed.",
                  name: "gallery_forms_bulk_user_action[member_ids][]",
                  options: USERS.map do |user|
                    NitroKit::Choice.new(
                      label: "#{user.name} — #{user.email}",
                      value: user.id,
                      disabled: user.role == :owner
                    )
                  end,
                  value: bulk_action.member_ids
                )
                form.field(
                  :action,
                  as: :select,
                  label: "Action",
                  options: [
                    [ "Resend invitation", "remind" ],
                    [ "Suspend access", "suspend" ],
                    [ "Remove from workspace", "remove" ]
                  ],
                  prompt: "Choose an action",
                  required: true
                )
                form.submit(
                  "Review 2 selected users",
                  id: "gallery-users-bulk-review",
                  data: { turbo_submits_with: "Preparing review…" }
                )
              end
            end
            render NitroKit::Button.new(
              "Cancel bulk action",
              id: "gallery-users-bulk-cancel",
              href: entry_path(entry, state: "index")
            )
          end
        end
      end

      def render_bulk_confirmation
        bulk_action = Gallery::Forms::BulkUserAction.new(
          member_ids: %w[mem_annie mem_mary],
          action: "suspend",
          confirmed: false
        )

        render NitroKit::DangerZone.new(
          title: "Confirm suspension for 2 users",
          description: "Active sessions end immediately and the selected users lose workspace access.",
          id: "gallery-users-bulk-confirmation-zone"
        ) do |zone|
          zone.confirmation do
            render NitroKit::Alert.new(id: "gallery-users-bulk-warning", variant: :warning) do |alert|
              alert.title("Active sessions will end immediately")
              alert.description("Suspended users cannot sign in, accept invitations, or use personal API credentials until restored.")
            end
            ul(data: { gallery: "bulk-user-summary" }) do
              li { "Annie Easley — annie.easley@example.test — already suspended" }
              li { "Mary Jackson — mary.jackson@example.test — currently active" }
            end
            form_with(
              model: bulk_action,
              url: "#confirm-bulk-users",
              builder: NitroKit::FormBuilder,
              id: "gallery-users-bulk-confirmation-form",
              data: { turbo_frame: "gallery-users-frame" }
            ) do |form|
              form.group do
                render NitroKit::Input.new(
                  type: :hidden,
                  name: "gallery_forms_bulk_user_action[action]",
                  value: bulk_action.action
                )
                bulk_action.member_ids.each do |member_id|
                  render NitroKit::Input.new(
                    type: :hidden,
                    name: "gallery_forms_bulk_user_action[member_ids][]",
                    value: member_id
                  )
                end
                form.field(
                  :confirmed,
                  as: :checkbox,
                  label: "I understand this ends active sessions for the selected users",
                  required: true
                )
                form.submit(
                  "Suspend 2 users",
                  id: "gallery-users-bulk-confirm",
                  variant: :destructive,
                  data: { turbo_submits_with: "Suspending users…" }
                )
              end
            end
          end
          zone.escape NitroKit::Button.new(
            "Back to selection",
            id: "gallery-users-bulk-confirmation-back",
            href: entry_path(entry, state: "bulk")
          )
        end
      end

      def render_bulk_complete
        render NitroKit::Card.new(id: "gallery-users-bulk-complete-card") do |card|
          card.title("Bulk action complete", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Alert.new(id: "gallery-users-bulk-complete", variant: :success) do |alert|
                alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-users-bulk-complete-icon"))
                alert.title("2 user records were updated")
                alert.description("Mary Jackson and Annie Easley are suspended. One active session ended; no invitations were changed.")
              end
              render NitroKit::DetailsTable.new(
                bulk_operation,
                data: { gallery: "bulk-operation-summary" }
              ) do |details|
                details.fields(:operation, :performed_by, :audit_records)
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new(
              "Return to users",
              id: "gallery-users-bulk-complete-return",
              href: entry_path(entry, state: "index"),
              variant: :primary
            )
          end
        end
      end

      def render_mobile
        user = USERS.fetch(4)

        render NitroKit::Card.new(id: "gallery-users-mobile-card") do |card|
          card.title("Margaret Hamilton — Director of Software Engineering", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Avatar.new(
                alt: user.name,
                fallback: initials(user.name),
                size: :lg,
                id: "gallery-users-mobile-avatar"
              )
              render NitroKit::Badge.new("Active member", id: "gallery-users-mobile-status", color: :success)
              render NitroKit::DetailsTable.new(
                user,
                data: { gallery: "user-mobile-metadata" }
              ) do |details|
                details.field(:email)
                details.field(:workspace, value: "Analytical Engines — International Research, Production, and Reliability Engineering")
                details.field(:access, value: "Seven production environments, audit exports, billing reports, and incident response schedules")
                details.field(:last_sign_in, value: "July 13, 2026 at 08:59 UTC from a managed security key in Cambridge, Massachusetts")
              end
              p do
                "Suspending this user ends three active browser sessions and pauses two personal deployment credentials. " \
                  "Workspace-owned automations continue running."
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::ButtonGroup.new(id: "gallery-users-mobile-actions", label: "Actions for Margaret Hamilton") do |group|
              group.button("Edit role", id: "gallery-users-mobile-edit", href: "#edit-role", variant: :primary)
              group.button("Suspend access", id: "gallery-users-mobile-suspend", href: "#suspend", variant: :destructive)
            end
          end
        end
      end

      def render_search_form(search, disabled: false)
        form_with(
          model: search,
          url: "#search-users",
          method: :get,
          builder: NitroKit::FormBuilder,
          id: "gallery-users-search-form",
          data: { turbo_frame: "gallery-users-frame" }
        ) do |form|
          form.group do
            form.field(
              :query,
              as: :search,
              label: "Name or email",
              placeholder: "Search users",
              autocomplete: "off",
              disabled:
            )
            form.field(
              :status,
              as: :select,
              label: "Status",
              options: [
                [ "All statuses", "all" ],
                [ "Active", "active" ],
                [ "Invited", "invited" ],
                [ "Suspended", "suspended" ]
              ],
              disabled:
            )
            form.submit(
              disabled ? "Searching…" : "Search users",
              id: "gallery-users-search-submit",
              disabled:,
              data: { turbo_submits_with: "Searching…" }
            )
          end
        end
      end

      def bulk_operation
        BulkOperation.new(
          operation: "bulk_suspend_2026_07_13_0922",
          performed_by: "Ada Lovelace",
          audit_records: "Two events created"
        )
      end

      def render_index_pagination
        render NitroKit::PaginationBar.new(id: "gallery-users-index-pagination-bar") do |bar|
          bar.summary("Showing 1–8 of 128 workspace users", html: { id: "gallery-users-index-summary" })
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-users-index-pagination",
              label: "Workspace user pages"
            )
          ) do |pagination|
            pagination.prev(id: "gallery-users-index-pagination-previous")
            pagination.page(1, current: true, id: "gallery-users-index-pagination-page-1")
            pagination.page(2, href: users_page_path(state: "index", page: 2), id: "gallery-users-index-pagination-page-2")
            pagination.page(3, href: users_page_path(state: "index", page: 3), id: "gallery-users-index-pagination-page-3")
            pagination.ellipsis(label: "Pages 4 through 15 omitted")
            pagination.page(16, href: users_page_path(state: "index", page: 16), id: "gallery-users-index-pagination-page-16")
            pagination.next(
              href: users_page_path(state: "index", page: 2),
              id: "gallery-users-index-pagination-next"
            )
          end
        end
      end

      def render_search_pagination
        render NitroKit::PaginationBar.new(id: "gallery-users-search-pagination-bar") do |bar|
          bar.summary(
            "Showing 11–15 of 37 active users matching “a”",
            html: { id: "gallery-users-search-summary" },
            aria: { live: "polite" }
          )
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-users-search-pagination",
              label: "Filtered workspace user pages"
            )
          ) do |pagination|
            pagination.prev(
              href: users_page_path(state: "search", page: 2, query: "a", status: "active"),
              id: "gallery-users-search-pagination-previous"
            )
            pagination.page(
              1,
              href: users_page_path(state: "search", page: 1, query: "a", status: "active"),
              id: "gallery-users-search-pagination-page-1"
            )
            pagination.page(
              2,
              href: users_page_path(state: "search", page: 2, query: "a", status: "active"),
              id: "gallery-users-search-pagination-page-2"
            )
            pagination.page(3, current: true, id: "gallery-users-search-pagination-page-3")
            pagination.page(
              4,
              href: users_page_path(state: "search", page: 4, query: "a", status: "active"),
              id: "gallery-users-search-pagination-page-4"
            )
            pagination.ellipsis(label: "Pages 5 through 7 omitted")
            pagination.page(
              8,
              href: users_page_path(state: "search", page: 8, query: "a", status: "active"),
              id: "gallery-users-search-pagination-page-8"
            )
            pagination.next(
              href: users_page_path(state: "search", page: 4, query: "a", status: "active"),
              id: "gallery-users-search-pagination-next"
            )
          end
        end
      end

      def users_page_path(state:, page:, query: nil, status: nil)
        gallery_composition_path(**{ slug: entry.slug, state:, page:, query:, status: }.compact)
      end

      def render_users_table_content(table, users, id:, caption:)
        table.caption(caption)
        table.thead do
          table.tr do
            table.th("User")
            table.th("Email")
            table.th("Role")
            table.th("Status")
            table.th("Joined")
            table.th("Action", align: :right)
          end
        end
        table.tbody do
          users.each do |user|
            table.tr do
              table.th(scope: :row) do
                render NitroKit::Avatar.new(
                  src: user.avatar_url,
                  alt: user.name,
                  fallback: initials(user.name),
                  size: :sm,
                  id: "#{id}-#{user.id}-avatar"
                )
                plain user.name
              end
              table.td(user.email)
              table.td(user.role.to_s.humanize)
              table.td do
                render NitroKit::Badge.new(
                  user.status.to_s.humanize,
                  id: "#{id}-#{user.id}-status",
                  color: user_status_color(user.status),
                  size: :sm
                )
              end
              table.td(user.joined_on&.to_fs(:long) || "Invitation pending")
              table.td(align: :right) do
                render NitroKit::Button.new(
                  "View",
                  id: "#{id}-#{user.id}-view",
                  href: entry_path(entry, state: "detail"),
                  size: :sm,
                  aria: { label: "View #{user.name}" }
                )
              end
            end
          end
        end
      end

      def render_activity_table(user)
        render NitroKit::Table.new(id: "gallery-users-detail-activity") do |table|
          table.caption("Recent activity for #{user.name}")
          table.thead do
            table.tr do
              table.th("Event")
              table.th("Resource")
              table.th("When")
            end
          end
          table.tbody do
            table.tr do
              table.th("Deployed", scope: :row)
              table.td("Billing portal to production")
              table.td("July 13, 2026 at 08:42 UTC")
            end
            table.tr do
              table.th("Approved", scope: :row)
              table.td("Invoice export retention change")
              table.td("July 12, 2026 at 13:08 UTC")
            end
            table.tr do
              table.th("Signed in", scope: :row)
              table.td("Recovery code followed by security key registration")
              table.td("July 9, 2026 at 07:52 UTC")
            end
          end
        end
      end


      def state_description
        {
          "index" => "A dense first page combines identity, role, status, dates, row actions, boundaries, and an omitted range.",
          "detail" => "Identity, security posture, access state, recent activity, and account actions form one record.",
          "search" => "A GET-style labelled search preserves its query through a deterministic middle pagination range.",
          "empty" => "A precise empty result retains filters, explains recovery, and offers a reset action.",
          "loading" => "A busy live region disables search while preserving the incoming query and table shape.",
          "error" => "A durable failure state identifies the request and offers explicit recovery routes.",
          "bulk" => "Native checkbox selection and a typed action establish a review-before-apply workflow.",
          "bulk-confirmation" => "A destructive summary carries selected IDs forward and requires explicit consent.",
          "bulk-complete" => "A deterministic outcome identifies affected users, sessions, actor, and audit records.",
          "mobile" => "Long identity, workspace, access, security, and consequence copy pressure a narrow detail view."
        }.fetch(state)
      end

      def initials(name)
        name.split.map(&:first).join.first(2).upcase
      end

      def user_status_color(status)
        { active: :success, invited: :info, suspended: :danger }.fetch(status)
      end
    end
  end
end
