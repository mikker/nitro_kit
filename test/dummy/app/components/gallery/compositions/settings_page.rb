module Gallery
  module Compositions
    class SettingsPage < Page
      include Phlex::Rails::Helpers::FormWith

      private

      def page_template
        render_composition_header(eyebrow: "Settings")

        render Section.new(
          slug: "settings-screen",
          title: "Workspace settings",
          description: "Component-composed profile, security, notification, integration, and appearance settings under real pressure."
        ) do
          render_example(
            slug: "settings-#{state}",
            title: state.to_s.humanize,
            description: state_description,
            mode: :full_width
          ) do
            main(
              id: "gallery-settings-surface",
              aria: { busy: loading? ? "true" : nil },
              data: {
                gallery: "composition-surface",
                gallery_composition: "settings",
                gallery_composition_state: state,
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-settings-container") do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-settings-stack") do
                  render NitroKit::SettingsLayout.new(id: "gallery-settings-layout") do |layout|
                    layout.navigation(label: "Settings sections") do
                      settings_sections.each do |slug, label|
                        layout.item(
                          label,
                          href: entry_path(entry, state: slug),
                          current: setting_section == slug
                        )
                      end
                    end
                    layout.content { render_state }
                  end
                end
              end
            end
          end
        end
      end

      def render_state
        case setting_section
        when "profile"
          render_profile
        when "security"
          render_security
        when "notifications"
          render_notifications
        when "integrations"
          render_integrations
        when "appearance"
          render_appearance
        end
      end

      def render_profile
        profile = profile_example

        render NitroKit::FormSection.new(
          title: "Profile",
          description: "Public details shown to workspace members in activity, assignments, and security events.",
          id: "gallery-settings-profile-section"
        ) do |section|
          if state == "profile-validation"
            section.status NitroKit::Alert.new(id: "gallery-settings-profile-error", variant: :error) do |alert|
              alert.title("Profile needs attention")
              alert.description(profile.errors.full_messages.to_sentence)
            end
          elsif state == "profile-success"
            section.status NitroKit::Alert.new(id: "gallery-settings-profile-success", variant: :success) do |alert|
              alert.title("Profile saved")
              alert.description("Your name, email, time zone, and biography are up to date.")
            end
          end

          section.form do
            form_with(
              model: profile,
              scope: :profile,
              url: "#settings-profile",
              builder: NitroKit::FormBuilder,
              id: "gallery-settings-profile-form"
            ) do |form|
              form.fieldset(
                legend: "Public profile",
                description: "Workspace members see these details in activity, assignments, and security events.",
                html: { id: "gallery-settings-profile-fieldset" }
              ) do
                form.group(html: { id: "gallery-settings-profile-fields" }) do
                  form.field(:name, required: true, autocomplete: "name")
                  form.field(:email, as: :email, required: true, autocomplete: "email")
                  form.field(
                    :time_zone,
                    as: :select,
                    options: Gallery::Forms::Profile::TIME_ZONES,
                    prompt: "Choose a time zone",
                    required: true
                  )
                  form.field(
                    :bio,
                    as: :textarea,
                    description: "A short introduction of at most 280 characters.",
                    maxlength: 280
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-settings-profile-toolbar") do |toolbar|
                toolbar.trailing do
                  form.submit(
                    "Save profile",
                    id: "gallery-settings-profile-submit",
                    data: { turbo_submits_with: "Saving profile…" }
                  )
                end
              end
            end
          end
        end
      end

      def render_security
        disabled = state == "security-disabled"
        settings = Gallery::SettingsFormExamples.security

        render NitroKit::FormSection.new(
          title: "Password and sessions",
          description: "Changing the password signs out other browser sessions.",
          id: "gallery-settings-security-section"
        ) do |section|
          if disabled
            section.status NitroKit::Alert.new(id: "gallery-settings-security-disabled", variant: :warning) do |alert|
              alert.title("Security changes temporarily disabled")
              alert.description("An organization-wide credential rotation is in progress until 10:00 UTC.")
            end
          end

          section.form do
            form_with(
              model: settings,
              scope: :security,
              url: "#settings-security",
              builder: NitroKit::FormBuilder,
              id: "gallery-settings-security-form"
            ) do |form|
              form.fieldset(
                legend: "Account security",
                description: "Changing the password signs out other browser sessions.",
                disabled:,
                html: { id: "gallery-settings-security-fieldset" }
              ) do
                form.group do
                  form.field(
                    :current_password,
                    as: :password,
                    label: "Current password",
                    autocomplete: "current-password",
                    required: true,
                    disabled:,
                    value: nil
                  )
                  form.field(
                    :new_password,
                    as: :password,
                    label: "New password",
                    description: "Use at least 12 characters.",
                    autocomplete: "new-password",
                    required: true,
                    disabled:,
                    value: nil
                  )
                  form.field(
                    :session_timeout,
                    as: :select,
                    label: "Session timeout",
                    options: [ [ "15 minutes", 15 ], [ "30 minutes", 30 ], [ "1 hour", 60 ], [ "8 hours", 480 ] ],
                    disabled:
                  )
                  form.field(
                    :two_factor,
                    as: :switch,
                    label: "Require two-factor authentication",
                    description: "Recovery codes remain available to workspace owners.",
                    disabled:
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-settings-security-toolbar") do |toolbar|
                toolbar.trailing do
                  form.submit(
                    disabled ? "Security changes disabled" : "Update security",
                    id: "gallery-settings-security-submit",
                    disabled:,
                    data: { turbo_submits_with: "Updating security…" }
                  )
                end
              end
            end
          end
        end
        render_security_sessions(disabled:)
      end

      def render_security_sessions(disabled:)
        render NitroKit::DataSection.new(
          title: "Active sessions",
          description: "Signed-in browser sessions can be revoked without changing the current session.",
          id: "gallery-settings-sessions-section"
        ) do |section|
          section.table NitroKit::Table.new(
            id: "gallery-settings-sessions-table",
            table_html: { id: "gallery-settings-sessions-table-element" }
          ) do |table|
              table.caption("Signed-in browser sessions")
              table.thead do
                table.tr do
                  table.th("Browser")
                  table.th("Location")
                  table.th("Action", align: :right)
                end
              end
              table.tbody do
                [ [ "Safari 20 · current", "Copenhagen, Denmark" ], [ "Chrome 142", "London, United Kingdom" ] ].each_with_index do |(browser, location), index|
                  table.tr do
                    table.th(browser, scope: :row)
                    table.td(location)
                    table.td(align: :right) do
                      render NitroKit::Button.new(
                        index.zero? ? "Current session" : "Revoke",
                        id: "gallery-settings-session-#{index + 1}-action",
                        size: :sm,
                        disabled: disabled || index.zero?
                      )
                    end
                  end
                end
              end
          end
        end
      end

      def render_notifications
        settings = Gallery::SettingsFormExamples.notifications

        render NitroKit::FormSection.new(
          title: "Notifications",
          description: "Choose how workspace security, deployment, and digest events are delivered.",
          id: "gallery-settings-notifications-section"
        ) do |section|
          if state == "notifications-success"
            section.status NitroKit::Alert.new(
              id: "gallery-settings-notifications-success",
              variant: :success
            ) do |alert|
              alert.title("Notification preferences saved")
              alert.description("Security and deployment alerts will be delivered immediately.")
            end
          end

          section.form do
            form_with(
              model: settings,
              scope: :notifications,
              url: "#settings-notifications",
              builder: NitroKit::FormBuilder,
              id: "gallery-settings-notifications-form"
            ) do |form|
              form.fieldset(
                legend: "Workspace notifications",
                description: "Security notices are always sent to workspace owners.",
                html: { id: "gallery-settings-notifications-fieldset" }
              ) do
                form.group do
                  form.field(
                    :security_alerts,
                    as: :switch,
                    label: "Security alerts",
                    description: "Sign-ins, recovery codes, and credential changes."
                  )
                  form.field(
                    :deployment_alerts,
                    as: :switch,
                    label: "Deployment alerts",
                    description: "Production completion, rollback, and failure events."
                  )
                  form.field(
                    :weekly_digest,
                    as: :checkbox,
                    label: "Weekly workspace digest",
                    description: "A Monday summary of activity, access, and billing."
                  )
                  form.field(
                    :delivery_frequency,
                    as: :radio_group,
                    label: "Delivery frequency",
                    options: [
                      [ "Immediately", "immediately" ],
                      [ "Hourly summary", "hourly" ],
                      [ "Daily summary", "daily" ]
                    ],
                    required: true
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-settings-notifications-toolbar") do |toolbar|
                toolbar.trailing do
                  form.submit(
                    "Save notifications",
                    id: "gallery-settings-notifications-submit",
                    data: { turbo_submits_with: "Saving notifications…" }
                  )
                end
              end
            end
          end
        end
      end

      def render_integrations
        case state
        when "integrations-empty"
          render_empty_integrations
        when "integrations-error"
          render_integration_error
        else
          render_integration_collection(long: state == "long-content")
        end
      end

      def render_empty_integrations
        render NitroKit::DataSection.new(
          title: "Connected services",
          description: "Services synchronize deployments, errors, and workspace notifications.",
          id: "gallery-settings-integrations-empty-section"
        ) do |section|
          section.empty_state NitroKit::EmptyState.new(
            title: "No integrations connected",
            description: "Connect a service when this workspace is ready to share operational events.",
            level: 3,
            id: "gallery-settings-integrations-empty"
          ) do |empty|
            empty.icon NitroKit::Icon.new(:plug, id: "gallery-settings-integrations-empty-icon")
            empty.action NitroKit::Button.new(
              "Browse integrations",
              id: "gallery-settings-integrations-empty-action",
              href: "#integration-catalog",
              variant: :primary
            )
          end
        end
      end

      def render_integration_error
        integration = Gallery::Data.integrations.fetch(1)

        render NitroKit::Alert.new(id: "gallery-settings-integrations-error", variant: :error) do |alert|
          alert.title("Slack connection expired")
          alert.description("Reconnect before workspace notifications can be delivered again.")
        end
        render_integration_card(integration, description: integration.description)
      end

      def render_integration_collection(long:)
        render NitroKit::Card.new(id: "gallery-settings-integrations-heading-card") do |card|
          card.title("Connected services", level: 4)
          card.body do
            render NitroKit::Toolbar.new(id: "gallery-settings-integrations-heading-toolbar") do |toolbar|
              toolbar.leading do
                p do
                  if long
                    "Manage every external service that receives deployment activity, release metadata, workspace access " \
                      "changes, billing notices, and customer-visible incident updates from this unusually long-named workspace."
                  else
                    "Manage connections used by deployments, errors, and team notifications."
                  end
                end
              end
              toolbar.trailing do
                render NitroKit::Button.new(
                  "Connect another service",
                  id: "gallery-settings-integrations-connect",
                  href: "#integration-catalog",
                  variant: :primary
                )
              end
            end
          end
        end

        Gallery::Data.integrations.each do |integration|
          description = if long
            "#{integration.description} This connection applies to Analytical Engines — Research and Production " \
              "and preserves deterministic delivery history for every workspace administrator."
          else
            integration.description
          end
          render_integration_card(integration, description:)
        end
      end

      def render_integration_card(integration, description:)
        render NitroKit::Card.new(id: "gallery-settings-integration-#{integration.id}") do |card|
          card.title(integration.name, level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Badge.new(
                integration.status.to_s.humanize,
                id: "gallery-settings-integration-#{integration.id}-status",
                color: integration_color(integration.status),
                size: :sm
              )
              p { description }
            end
          end
          card.footer do
            render NitroKit::Button.new(
              integration.status == :available ? "Connect" : "Manage",
              id: "gallery-settings-integration-#{integration.id}-action",
              href: "#integration-#{integration.id}",
              variant: integration.status == :action_required ? :primary : :default
            )
          end
        end
      end

      def render_appearance
        disabled = state == "appearance-loading"
        settings = Gallery::SettingsFormExamples.appearance

        render NitroKit::FormSection.new(
          title: "Appearance",
          description: "Preferences follow your account across workspaces and browser sessions.",
          id: "gallery-settings-appearance-section"
        ) do |section|
          if disabled
            section.status NitroKit::Alert.new(id: "gallery-settings-appearance-loading") do |alert|
              alert.title("Applying appearance settings")
              alert.description("Theme, density, and motion preferences are synchronizing across open sessions.")
            end
          end

          section.form do
            form_with(
              model: settings,
              scope: :appearance,
              url: "#settings-appearance",
              builder: NitroKit::FormBuilder,
              id: "gallery-settings-appearance-form"
            ) do |form|
              form.fieldset(
                legend: "Interface preferences",
                description: "Preferences follow your account across workspaces and browser sessions.",
                disabled:,
                html: { id: "gallery-settings-appearance-fieldset" }
              ) do
                form.group do
                  form.field(
                    :theme,
                    as: :radio_group,
                    label: "Theme",
                    options: [ [ "Use system setting", "system" ], [ "Light", "light" ], [ "Dark", "dark" ] ],
                    disabled:
                  )
                  form.field(
                    :density,
                    as: :radio_group,
                    label: "Interface density",
                    options: [ [ "Comfortable", "comfortable" ], [ "Compact", "compact" ] ],
                    disabled:
                  )
                  form.field(
                    :reduce_motion,
                    as: :switch,
                    label: "Reduce interface motion",
                    description: "Also respects the operating system preference.",
                    disabled:
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-settings-appearance-toolbar") do |toolbar|
                toolbar.trailing do
                  form.submit(
                    disabled ? "Applying settings…" : "Save appearance",
                    id: "gallery-settings-appearance-submit",
                    disabled:,
                    data: { turbo_submits_with: "Applying settings…" }
                  )
                end
              end
            end
          end
        end
      end

      def profile_example
        return Gallery::FormExamples.profile(:invalid) if state == "profile-validation"
        return Gallery::FormExamples.profile unless state == "mobile"

        Gallery::Forms::Profile.new(
          name: "Dr. Katherine Coleman Goble Johnson — Orbital Mechanics and Flight Research",
          email: "katherine.johnson+analytical-engines-research-and-production@example.test",
          time_zone: "America/New_York",
          bio: "I verify trajectories, launch windows, and emergency return paths for teams working across many regions."
        )
      end

      def settings_sections
        [
          [ "profile", "Profile" ],
          [ "security", "Security" ],
          [ "notifications", "Notifications" ],
          [ "integrations", "Integrations" ],
          [ "appearance", "Appearance" ]
        ]
      end

      def setting_section
        return "profile" if %w[profile profile-validation profile-success mobile].include?(state)
        return "security" if state.start_with?("security")
        return "notifications" if state.start_with?("notifications")
        return "integrations" if state.start_with?("integrations") || state == "long-content"

        "appearance"
      end

      def loading?
        state == "appearance-loading"
      end

      def integration_color(status)
        { connected: :success, action_required: :danger, available: :neutral }.fetch(status)
      end


      def state_description
        {
          "profile" => "A complete model-backed profile form with grouped fields and explicit help.",
          "profile-validation" => "Real Active Model errors connect the summary, fields, and native controls.",
          "profile-success" => "A successful save leaves the updated settings visible and editable.",
          "security" => "Password, two-factor, timeout, and session revocation settings in one section.",
          "security-disabled" => "An organization-wide operation disables every security mutation honestly.",
          "notifications" => "Submittable switches, checkbox values, and a required delivery-frequency group.",
          "notifications-success" => "A successful preference save confirms the resulting delivery behavior.",
          "integrations" => "Connected, action-required, and available service records with explicit actions.",
          "integrations-empty" => "A meaningful empty state directs the user to the integration catalog.",
          "integrations-error" => "An expired connection explains impact and offers one recovery action.",
          "appearance" => "Theme, density, and motion choices use native radio and switch semantics.",
          "appearance-loading" => "The appearance form stays visible, busy, and completely disabled while saving.",
          "long-content" => "Long workspace and integration copy pressure repeated settings structures.",
          "mobile" => "Long identity values stress the profile form on a narrow mobile-width surface."
        }.fetch(state)
      end
    end
  end
end
