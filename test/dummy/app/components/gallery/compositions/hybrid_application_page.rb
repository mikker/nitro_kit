module Gallery
  module Compositions
    class HybridApplicationPage < ApplicationPage
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
          slug: "hybrid-application-states",
          description: "The hybrid shell combines persistent navigation with contextual header actions across complete, missing, and failed account settings."
        ) do
          application_example(
            "Populated system settings",
            slug: "hybrid-application-populated",
            description: "Two synchronized appearance pickers, profile media, record details, a Rails form, account actions, and a saved toast form one settings application.",
            source: :render_hybrid_populated
          ) { render_hybrid_populated }

          application_example(
            "Missing light profile",
            slug: "hybrid-application-missing",
            description: "Absent media and optional record values remain explicit while the application offers one clear recovery path.",
            source: :render_hybrid_missing
          ) { render_hybrid_missing }

          application_example(
            "Failed dark access request",
            slug: "hybrid-application-error",
            description: "Authorization failure, invalid fields, disabled submission, a native review dialog, and an error notification stay distinct.",
            source: :render_hybrid_error
          ) { render_hybrid_error }
        end
      end

      def render_hybrid_populated
        render NitroKit::AppShell.new(
          id: "gallery-hybrid-application-populated",
          layout: :hybrid,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "hybrid",
            gallery_application_state: "populated"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Admin" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-hybrid-application-populated-navigation",
              current: :settings,
              context: "Team plan",
              appearance_picker_id: "gallery-hybrid-application-navigation-appearance"
            )
          end
          shell.topbar do
            render NitroKit::Dropdown.new(id: "gallery-hybrid-application-account-menu") do |menu|
              menu.trigger("Ada Lovelace", variant: :ghost, size: :sm)
              menu.item("View public profile", href: "#public-profile")
              menu.item("Download account data")
              menu.separator
              menu.item("Sign out")
            end
          end
          shell.main do
            render_application_main do
              render NitroKit::PageHeader.new(
                title: "Account settings",
                description: "Manage the public profile and personal appearance without duplicating application chrome.",
                id: "gallery-hybrid-application-populated-header"
              )

              appearance_picker("gallery-hybrid-application-main-appearance", label: "Content appearance")

              render NitroKit::SettingsLayout.new(id: "gallery-hybrid-application-settings") do |layout|
                layout.navigation(label: "Account settings") do
                  layout.item("Profile", href: "#profile", current: true)
                  layout.item("Security", href: "#security")
                  layout.item("Notifications", href: "#notifications")
                  layout.item("Appearance", href: "#appearance")
                end
                layout.content do
                  render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
                    render NitroKit::ProgressiveImage.new(
                      attachment: demo_attachment,
                      alt: "Abstract cover for Ada Lovelace's workspace profile",
                      size: :sm,
                      id: "gallery-hybrid-application-profile-image"
                    )

                    render NitroKit::DetailsTable.new(
                      PROFILE,
                      id: "gallery-hybrid-application-profile-details"
                    ) do |details|
                      details.field(:name)
                      details.field(:email)
                      details.field(:role) do |role|
                        render NitroKit::Badge.new(role.to_s.humanize, color: :success, size: :sm)
                      end
                      details.fields(:website, :joined_on, :last_seen)
                    end

                    render NitroKit::SettingsSection.new(
                      title: "Public profile",
                      description: "These values appear in workspace activity and invitations.",
                      id: "gallery-hybrid-application-profile-settings-section"
                    ) do |section|
                      section.form do
                        form_with(
                          scope: :profile,
                          url: "#save-profile",
                          builder: NitroKit::FormBuilder,
                          id: "gallery-hybrid-application-profile-form"
                        ) do |form|
                          form.fieldset(legend: "Profile details") do
                            form.group do
                              form.field(:name, label: "Name", value: PROFILE.name, required: true)
                              form.field(:email, as: :email, label: "Email", value: PROFILE.email, required: true)
                              form.field(:website, as: :url, label: "Website", value: PROFILE.website)
                            end
                          end
                          form.submit("Save profile", id: "gallery-hybrid-application-profile-submit")
                        end
                      end
                    end
                  end
                end
              end

              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Account notifications",
                id: "gallery-hybrid-application-toast"
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

      def render_hybrid_missing
        render NitroKit::AppShell.new(
          id: "gallery-hybrid-application-missing",
          layout: :hybrid,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "hybrid",
            gallery_application_state: "missing",
            theme: "light"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Admin" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-hybrid-application-missing-navigation",
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
                id: "gallery-hybrid-application-missing-header"
              )

              render NitroKit::ProgressiveImage.new(
                attachment: nil,
                alt: "Invited teammate profile image",
                size: :sm,
                id: "gallery-hybrid-application-missing-image"
              )

              render NitroKit::DetailsTable.new(
                MISSING_PROFILE,
                id: "gallery-hybrid-application-missing-details"
              ) do |details|
                details.fields(:name, :email, :role, :website, :joined_on, :last_seen)
              end

              render NitroKit::EmptyState.new(
                title: "Profile setup has not started",
                description: "Resend the invitation or copy a fresh setup link for this teammate.",
                id: "gallery-hybrid-application-missing-state"
              ) do |empty|
                empty.icon NitroKit::Icon.new(:users)
                empty.action NitroKit::Button.new("Resend invitation", href: "#resend", variant: :primary)
                empty.action NitroKit::Button.new("Copy setup link", href: "#copy")
              end
            end
          end
        end
      end

      def render_hybrid_error
        render NitroKit::AppShell.new(
          id: "gallery-hybrid-application-error",
          layout: :hybrid,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "hybrid",
            gallery_application_state: "error",
            theme: "dark"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Admin" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-hybrid-application-error-navigation",
              current: :settings,
              context: "Restricted"
            )
          end
          shell.topbar do
            render NitroKit::Dialog.new(id: "gallery-hybrid-application-policy-dialog") do |dialog|
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
                description: "The request could not be submitted because its owner and justification are incomplete.",
                id: "gallery-hybrid-application-error-header"
              )

              render NitroKit::Alert.new(
                variant: :error,
                id: "gallery-hybrid-application-error-alert"
              ) do |alert|
                alert.icon NitroKit::Icon.new(:triangle_alert)
                alert.title("Access request needs attention")
                alert.description("Choose an owner and add a specific operational reason before asking an administrator to review it.")
              end

              render NitroKit::SettingsSection.new(
                title: "Production access",
                description: "Restricted fields remain visible so the failed request can be understood.",
                id: "gallery-hybrid-application-access-section"
              ) do |section|
                section.status NitroKit::Alert.new(
                  variant: :warning,
                  id: "gallery-hybrid-application-access-policy"
                ) do |alert|
                  alert.title("Submission is temporarily unavailable")
                  alert.description("A workspace owner must restore your access before this form can be retried.")
                end
                section.form do
                  form_with(
                    scope: :access_request,
                    url: "#request-access",
                    builder: NitroKit::FormBuilder,
                    id: "gallery-hybrid-application-access-form"
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
                      id: "gallery-hybrid-application-access-submit",
                      disabled: true
                    )
                  end
                end
              end

              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Access request notifications",
                id: "gallery-hybrid-application-error-toast"
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
