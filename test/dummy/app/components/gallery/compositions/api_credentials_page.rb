module Gallery
  module Compositions
    class ApiCredentialsPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        render_composition_header

        render Section.new(
          slug: "api-credentials-screen",
          title: "API credentials",
          description: "Inventory, creation, reveal-once, revocation, recovery, density, and mobile pressure."
        ) do
          render_example(
            slug: "api-credentials-#{state}",
            title: humanize_state(state),
            description: state_description,
            mode: :full_width
          ) do
            div(
              data: {
                gallery: "composition-surface",
                gallery_composition: "api-credentials",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-api-credentials-container") do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-api-credentials-stack") do
                  turbo_frame_tag("gallery-api-credentials-frame") { render_screen }
                end
              end
            end
          end
        end
      end

      def render_screen
        case state
        when "list", "dense", "mobile", "long"
          render_key_section(table_keys)
        when "empty"
          render_empty
        when "create", "validation", "loading"
          render_create_form
        when "reveal-once"
          render_reveal_once
        when "revoke-confirmation"
          render_revoke_confirmation
        when "revoked"
          render_revoked
        when "expired"
          render_expired
        when "error"
          render_error
        end
      end

      def render_key_section(keys)
        render NitroKit::DataSection.new(
          title: state == "dense" ? "Credential inventory" : "Active credentials",
          description: "#{keys.length} active #{'credential'.pluralize(keys.length)} with scope, recency, creation time, and lifecycle actions.",
          id: "gallery-api-credentials-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-api-credentials-actions", label: "Credential inventory actions")
          ) do |group|
            group.button(
              "Create credential",
              id: "gallery-api-credentials-footer-create",
              href: entry_path(entry, state: "create"),
              variant: :primary
            )
          end
          section.table NitroKit::Table.new(
            id: "gallery-api-credentials-table",
            table_aria: { label: "Workspace API credentials" }
          ) do |table|
            render_key_table_content(table, keys)
          end
        end
      end

      def render_key_table_content(table, keys)
        table.caption("#{keys.length} active API credentials")
        table.thead do
            table.tr do
              table.th("Credential")
              table.th("Access")
              table.th("Last used")
              table.th("Created")
              table.th("Actions", align: :right)
            end
          end
          table.tbody do
            keys.each do |key|
              table.tr do
                table.th(scope: :row) do
                  strong { key.name }
                  small { key.prefix }
                end
                table.td do
                  render NitroKit::Badge.new(
                    key.access.to_s.humanize,
                    id: "gallery-api-key-#{key.id}-access",
                    variant: :outline,
                    color: key.access == :read_write ? :warning : :info,
                    size: :sm
                  )
                end
                table.td(key.last_used_at ? format_time(key.last_used_at) : "Never")
                table.td(format_time(key.created_at))
                table.td(align: :right) { render_key_actions(key) }
              end
            end
          end
      end

      def render_key_actions(key)
        render NitroKit::ButtonGroup.new(
          id: "gallery-api-key-#{key.id}-actions",
          label: "Actions for #{key.name}"
        ) do |group|
          group.button(
            "Rotate",
            id: "gallery-api-key-#{key.id}-rotate",
            href: entry_path(entry, state: "create"),
            size: :sm
          )
          group.button(
            "Revoke",
            id: "gallery-api-key-#{key.id}-revoke",
            href: entry_path(entry, state: "revoke-confirmation"),
            size: :sm,
            variant: :destructive
          )
        end
      end

      def render_empty
        render NitroKit::DataSection.new(
          title: "API credentials",
          description: "Scoped credentials let applications access this workspace programmatically.",
          id: "gallery-api-credentials-empty-section"
        ) do |section|
          section.empty_state NitroKit::EmptyState.new(
            title: "No API credentials",
            description: "Create a scoped credential when an application needs programmatic workspace access.",
            level: 3,
            id: "gallery-api-credentials-empty"
          ) do |empty|
            empty.icon NitroKit::Icon.new(:key_round, id: "gallery-api-credentials-empty-icon")
            empty.action NitroKit::Button.new(
              "Create first credential",
              id: "gallery-api-credentials-empty-create",
              href: entry_path(entry, state: "create"),
              variant: :primary
            )
          end
        end
      end

      def render_create_form
        key = Gallery::FormExamples.api_key(state == "validation" ? :invalid : :valid)
        disabled = state == "loading"

        render NitroKit::SettingsSection.new(
          title: "Create an API credential",
          description: "Limit each credential to the access and lifetime its application needs.",
          id: "gallery-api-credential-section"
        ) do |section|
          if state == "validation"
            section.status NitroKit::Alert.new(id: "gallery-api-credential-validation", variant: :destructive) do |alert|
              alert.title("The credential could not be created")
              alert.description("Name the credential and choose supported access and expiration values.")
            end
          end
          section.form do
            form_with(
              model: key,
              url: "#api-credential",
              builder: NitroKit::FormBuilder,
              id: "gallery-api-credential-form",
              data: { turbo_frame: "gallery-api-credentials-frame" }
            ) do |form|
              form.group do
                form.field(
                  :name,
                  label: "Credential name",
                  description: "Use the application or automation name.",
                  autocomplete: "off",
                  required: true,
                  disabled:
                )
                form.field(
                  :access,
                  as: :select,
                  label: "Access level",
                  options: [ [ "Read only", "read_only" ], [ "Read and write", "read_write" ] ],
                  required: true,
                  disabled:
                )
                form.field(
                  :expires_in_days,
                  as: :select,
                  label: "Expires after",
                  options: [ [ "30 days", 30 ], [ "90 days", 90 ], [ "180 days", 180 ], [ "365 days", 365 ] ],
                  required: true,
                  disabled:
                )
                form.submit(
                  disabled ? "Creating credential…" : "Create credential",
                  id: "gallery-api-credential-submit",
                  disabled:,
                  data: { turbo_submits_with: "Creating credential…" }
                )
              end
            end
          end
        end
      end

      def render_reveal_once
        reveal = Gallery::Data.api_key_reveal

        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-api-credential-reveal-stack") do
          render NitroKit::Alert.new(id: "gallery-api-credential-reveal-warning", variant: :warning) do |alert|
            alert.icon(NitroKit::Icon.new(:triangle_alert, id: "gallery-api-credential-reveal-warning-icon"))
            alert.title("Copy this credential now")
            alert.description("For security, the full value is shown once and cannot be recovered later.")
          end
          render NitroKit::Field.new(
            nil,
            :secret,
            id: "gallery-api-credential-secret",
            name: "api_credential[secret]",
            value: reveal.secret,
            label: "New credential",
            description: "Created #{format_time(reveal.revealed_at)} · expires #{format_time(reveal.expires_at)}",
            readonly: true,
            autocomplete: "off"
          )
          render NitroKit::Button.new(
            "Copy credential",
            id: "gallery-api-credential-copy",
            type: :button,
            data: { credential: reveal.secret }
          )
          render NitroKit::Button.new(
            "I stored this credential",
            id: "gallery-api-credentials-footer-stored",
            href: entry_path(entry, state: "list"),
            variant: :primary
          )
        end
      end

      def render_revoke_confirmation
        key = Gallery::Data.api_keys.first
        revocation = Gallery::OperationsFormExamples.api_key_revocation

        render NitroKit::DangerZone.new(
          title: "Revoke production access",
          description: "Requests using #{key.prefix} will fail immediately and the credential cannot be recovered.",
          id: "gallery-api-credential-revoke-zone"
        ) do |zone|
          zone.confirmation do
            render NitroKit::Dialog.new(id: "gallery-api-credential-revoke-dialog") do |dialog|
              dialog.panel(
                title: "Revoke #{key.name}?",
                description: "Requests using #{key.prefix} will fail immediately. This action cannot be undone.",
                nonmodal: true
              ) do
                form_with(
                  model: revocation,
                  url: "#api-credential-revoke",
                  builder: NitroKit::FormBuilder,
                  id: "gallery-api-credential-revoke-form",
                  data: { turbo_frame: "gallery-api-credentials-frame" }
                ) do |form|
                  form.group do
                    form.hidden_field(:key_id)
                    form.field(
                      :acknowledged,
                      as: :checkbox,
                      label: "I understand that requests using this credential will fail immediately",
                      required: true
                    )
                    form.submit(
                      "Revoke credential",
                      id: "gallery-api-credential-revoke-submit",
                      variant: :destructive,
                      data: { turbo_submits_with: "Revoking credential…" }
                    )
                    dialog.close_button(label: "Keep credential")
                  end
                end
              end
            end
          end
          zone.escape NitroKit::Button.new(
            "Keep credential",
            id: "gallery-api-credential-revoke-escape",
            href: entry_path(entry, state: "list")
          )
        end
      end

      def render_revoked
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-api-credential-revoked-stack") do
          render NitroKit::Alert.new(id: "gallery-api-credential-revoked", variant: :success) do |alert|
            alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-api-credential-revoked-icon"))
            alert.title("Production was revoked")
            alert.description("Requests using nk_live_7P3F now fail authentication and the audit event is available.")
          end
          render_back_to_credentials
        end
      end

      def render_expired
        issue = Gallery::Data.expired_api_key_issue

        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-api-credential-expired-stack") do
          render NitroKit::Alert.new(id: "gallery-api-credential-expired", variant: :warning) do |alert|
            alert.icon(NitroKit::Icon.new(:clock_alert, id: "gallery-api-credential-expired-icon"))
            alert.title("#{issue.key.name} expired")
            alert.description("#{issue.message} Expired #{format_time(issue.occurred_at)}.")
          end
          render NitroKit::Button.new(
            "Create replacement",
            id: "gallery-api-credentials-footer-replace",
            href: entry_path(entry, state: "create"),
            variant: :primary
          )
        end
      end

      def render_error
        issue = Gallery::Data.failed_api_key_issue

        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-api-credential-error-stack") do
          render NitroKit::Alert.new(id: "gallery-api-credential-error", variant: :destructive) do |alert|
            alert.icon(NitroKit::Icon.new(:circle_x, id: "gallery-api-credential-error-icon"))
            alert.title("#{issue.key.name} is still active")
            alert.description("#{issue.message} No credential or access state changed.")
          end
          render NitroKit::Button.new(
            "Retry revocation",
            id: "gallery-api-credentials-footer-retry",
            href: entry_path(entry, state: "revoke-confirmation"),
            variant: :primary
          )
        end
      end

      def render_back_to_credentials
        render NitroKit::Button.new(
          "Back to credentials",
          id: "gallery-api-credentials-footer-list",
          href: entry_path(entry, state: "list")
        )
      end

      def table_keys
        return Gallery::Data.dense_api_keys if state == "dense"
        return [ Gallery::Data.dense_api_keys.last ] if state == "long"

        Gallery::Data.api_keys
      end

      def format_time(time)
        time.utc.strftime("%b %-d, %Y %H:%M UTC")
      end

      def state_description
        {
          "list" => "A semantic inventory exposes scope, recency, creation, and labelled row actions.",
          "empty" => "The empty state explains what credentials do before offering creation.",
          "create" => "A real model collects a name, access boundary, and expiration.",
          "validation" => "Active Model errors cover the missing name and unsupported policy values.",
          "loading" => "Credential fields and submission are disabled while Turbo processes.",
          "reveal-once" => "A readonly secret and warning make the one-time security boundary explicit.",
          "revoke-confirmation" => "A native open dialog names the prefix and immediate consequence.",
          "revoked" => "Completion confirms request failure and audit history.",
          "expired" => "An expired credential offers an explicit replacement path.",
          "error" => "Failure copy confirms the existing credential remains active.",
          "long" => "A long automation name pressures the semantic inventory without truncation.",
          "dense" => "Six deterministic credentials pressure row actions and operational timestamps.",
          "mobile" => "The credential inventory remains semantic inside a narrow overflow surface."
        }.fetch(state)
      end
    end
  end
end
