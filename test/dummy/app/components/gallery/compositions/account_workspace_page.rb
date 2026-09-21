module Gallery
  module Compositions
    class AccountWorkspacePage < ApplicationPage
      Profile = ::Data.define(:name, :email, :role, :website, :joined_on, :last_seen)

      PROFILE = Profile.new(
        name: "Ada Lovelace",
        email: "ada@example.test",
        role: :owner,
        website: "https://example.test/ada",
        joined_on: Date.new(2024, 2, 12),
        last_seen: Time.zone.parse("2026-07-13 19:04:00 UTC")
      )

      MISSING_PROFILE = Profile.new(
        name: "Invited teammate",
        email: "new.member@example.test",
        role: nil,
        website: nil,
        joined_on: nil,
        last_seen: nil
      )

      private

      def application_template
        application_section(
          "Account workspace states",
          slug: "account-workspace-states",
          description: "The sidebar shell combines persistent navigation with contextual header actions across complete, missing, and failed account settings."
        ) do
          application_example(
            "Populated system settings",
            slug: "account-workspace-populated",
            description: "Two synchronized appearance pickers, profile media, record details, a Rails form, account actions, and a saved toast form one settings application.",
            source: :render_sidebar_populated
          ) { render_sidebar_populated }

          application_example(
            "Missing light profile",
            slug: "account-workspace-missing",
            description: "Absent media and optional record values remain explicit while the application offers one clear recovery path.",
            source: :render_sidebar_missing
          ) { render_sidebar_missing }

          application_example(
            "Failed dark access request",
            slug: "account-workspace-error",
            description: "Authorization failure, invalid fields, disabled submission, a native review dialog, and an error notification stay distinct.",
            source: :render_sidebar_error
          ) { render_sidebar_error }
        end
      end

      def render_sidebar_populated
        render NitroKit::AppShell.new(
          id: "gallery-account-workspace-populated",
          layout: :sidebar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "sidebar",
            gallery_application_state: "populated"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Admin" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-account-workspace-populated-navigation",
              current: :settings,
              account_menu: false,
              context: "Team plan",
              appearance_picker_id: "gallery-account-workspace-navigation-appearance"
            )
          end
          shell.topbar { render_account_menu(id: "gallery-account-workspace-account", placement: :bottom_end) }
          shell.main do
            render_application_main do
              render NitroKit::PageHeader.new(
                title: "Account settings",
                description: "Manage the public profile and personal appearance without duplicating application chrome.",
                id: "gallery-account-workspace-populated-header"
              )

              appearance_picker("gallery-account-workspace-main-appearance", label: "Content appearance")

              render NitroKit::SettingsLayout.new(id: "gallery-account-workspace-settings") do |layout|
                layout.navigation(label: "Account settings") do
                  layout.item("Profile", href: "#profile", current: true)
                  layout.item("Security", href: "#security")
                  layout.item("Notifications", href: "#notifications")
                  layout.item("Appearance", href: "#appearance")
                end
                layout.content do
                  render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
                    render NitroKit::Grid.new(cols: "1 md:2", gap: 4) do
                      render NitroKit::ProgressiveImage.new(
                        attachment: demo_attachment,
                        alt: "Abstract cover for Ada Lovelace's workspace profile",
                        size: :sm,
                        id: "gallery-account-workspace-profile-image"
                      )

                      render NitroKit::DetailsTable.new(
                        PROFILE,
                        label: "Account details",
                        id: "gallery-account-workspace-profile-details"
                      ) do |details|
                        details.field(:role) do |role|
                          render NitroKit::Badge.new(role.to_s.humanize, color: :success, size: :sm)
                        end
                        details.fields(:joined_on, :last_seen)
                      end
                    end

                    render NitroKit::SettingsSection.new(
                      title: "Public profile",
                      description: "These values appear in workspace activity and invitations.",
                      id: "gallery-account-workspace-profile-settings-section"
                    ) do |section|
                      section.form do
                        form_with(
                          scope: :profile,
                          url: "#save-profile",
                          builder: NitroKit::FormBuilder,
                          id: "gallery-account-workspace-profile-form"
                        ) do |form|
                          form.group do
                            form.field(:name, label: "Name", value: PROFILE.name, required: true)
                            form.field(:email, as: :email, label: "Email", value: PROFILE.email, required: true)
                            form.field(:website, as: :url, label: "Website", value: PROFILE.website)
                            form.submit("Save profile", id: "gallery-account-workspace-profile-submit")
                          end
                        end
                      end
                    end
                  end
                end
              end

              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Account notifications",
                id: "gallery-account-workspace-toast"
              ) do |toast|
                toast.item(
                  title: "Profile saved",
                  description: "Workspace activity now uses the updated public details.",
                  variant: :success
                )
              end
            end
          end
        end
      end

      def render_sidebar_missing
        render NitroKit::AppShell.new(
          id: "gallery-account-workspace-missing",
          layout: :sidebar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "sidebar",
            gallery_application_state: "missing",
            theme: "light"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Admin" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-account-workspace-missing-navigation",
              current: :people,
              context: "Invitations"
            )
          end
          shell.topbar do
            render NitroKit::Button.new("Invite teammate", href: "#invite", variant: :primary, size: :sm)
          end
          shell.main do
            render_application_main(size: :lg) do
              render NitroKit::PageHeader.new(
                title: "Invited teammate",
                id: "gallery-account-workspace-missing-header"
              )

              render NitroKit::ProgressiveImage.new(
                attachment: nil,
                alt: "Invited teammate profile image",
                size: :sm,
                id: "gallery-account-workspace-missing-image"
              )

              render NitroKit::DetailsTable.new(
                MISSING_PROFILE,
                label: "Invitation details",
                id: "gallery-account-workspace-missing-details"
              ) do |details|
                details.fields(:name, :email, :role, :website, :joined_on, :last_seen)
              end

              render NitroKit::EmptyState.new(
                title: "Profile setup has not started",
                description: "Resend the invitation or copy a fresh setup link for this teammate.",
                id: "gallery-account-workspace-missing-state"
              ) do |empty|
                empty.icon NitroKit::Icon.new(:users)
                empty.action NitroKit::Button.new("Resend invitation", href: "#resend", variant: :primary)
                empty.action NitroKit::Button.new("Copy setup link", href: "#copy")
              end
            end
          end
        end
      end

      def render_sidebar_error
        render NitroKit::AppShell.new(
          id: "gallery-account-workspace-error",
          layout: :sidebar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "sidebar",
            gallery_application_state: "error",
            theme: "dark"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Admin" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-account-workspace-error-navigation",
              current: :settings,
              context: "Restricted"
            )
          end
          shell.topbar do
            render NitroKit::Dialog.new(id: "gallery-account-workspace-policy-dialog") do |dialog|
              dialog.trigger("Review policy", size: :sm)
              dialog.panel(
                title: "Workspace access policy",
                description: "Only workspace owners may grant production access or change an administrator role."
              ) do
                dialog.close_button(label: "Close policy")
              end
            end
          end
          shell.main do
            render_application_main(size: :lg) do
              render NitroKit::PageHeader.new(
                title: "Request production access",
                description: "Review the incomplete request and ask a workspace owner to restore submission access.",
                id: "gallery-account-workspace-error-header"
              )

              render NitroKit::Alert.new(
                variant: :destructive,
                id: "gallery-account-workspace-error-alert"
              ) do |alert|
                alert.icon NitroKit::Icon.new(:triangle_alert)
                alert.title("Access request needs attention")
                alert.description("Choose an owner and add a specific operational reason before asking an administrator to review it.")
              end

              render NitroKit::SettingsSection.new(
                title: "Production access",
                description: "Restricted fields remain visible so the failed request can be understood.",
                id: "gallery-account-workspace-access-section"
              ) do |section|
                section.form do
                  form_with(
                    scope: :access_request,
                    url: "#request-access",
                    builder: NitroKit::FormBuilder,
                    id: "gallery-account-workspace-access-form"
                  ) do |form|
                    form.fieldset(legend: "Request details", disabled: true) do
                      form.group do
                        form.field(
                          :owner,
                          as: :select,
                          label: "Request owner",
                          include_blank: "Choose an owner",
                          options: [ [ "Ada Lovelace", "ada" ], [ "Grace Hopper", "grace" ] ],
                          errors: [ "must be selected" ]
                        )
                        form.field(
                          :justification,
                          as: :textarea,
                          label: "Operational justification",
                          value: "Need access",
                          rows: 4,
                          errors: [ "must explain the production task" ]
                        )
                      end
                    end
                    form.submit(
                      "Request access",
                      id: "gallery-account-workspace-access-submit",
                      disabled: true
                    )
                  end
                end
              end

              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Access request notifications",
                id: "gallery-account-workspace-error-toast"
              ) do |toast|
                toast.item(
                  title: "Access request was not sent",
                  description: "No workspace role or production permission changed.",
                  variant: :error
                )
              end
            end
          end
        end
      end
    end
  end
end
