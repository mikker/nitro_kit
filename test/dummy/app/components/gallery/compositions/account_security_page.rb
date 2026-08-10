module Gallery
  module Compositions
    class AccountSecurityPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      private

      def render_scenario
        render NitroKit::AuthShell.new(
          id: "gallery-account-security-shell",
          aria: {
            label: "Nitro account security",
            busy: state == "loading" ? "true" : nil
          }.compact
        ) do
          render_header

          case state
          when "recovery-request", "recovery-validation", "loading" then render_recovery_request
          when "recovery-sent" then render_message("Recovery email sent", "Use the link sent to ada@example.test within 30 minutes.", :mail_check, "Return to sign in", href: "#sign-in")
          when "reset" then render_password_reset
          when "reset-expired" then render_message("Recovery link expired", "Request a new link. No password or session changed.", :clock_alert, "Request another link", href: entry_path(entry, state: "recovery-request"))
          when "account-locked" then render_locked
          when "unlock-sent" then render_message("Unlock instructions sent", "The unlock link was sent without revealing whether other sessions remain active.", :mail_check, "Return to sign in", href: "#sign-in")
          when "two-factor-challenge", "two-factor-invalid" then render_two_factor
          when "recovery-code", "recovery-code-invalid" then render_recovery_code
          when "trusted-device" then render_trusted_device
          when "success" then render_message("Identity verified", "The account is unlocked and the current browser session is active.", :circle_check, "Continue to workspace", href: "#workspace")
          when "long" then render_long
          when "mobile" then render_mobile
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: "Secure your account",
          description: security_description,
          level: 4,
          id: "gallery-account-security-header"
        ) do |header|
          header.actions NitroKit::ButtonGroup.new(label: "Security help", id: "gallery-account-security-help") do |actions|
            actions.button("Get help", href: "mailto:support@example.test")
          end
        end
      end

      def render_recovery_request
        invalid = state == "recovery-validation"
        disabled = state == "loading"

        render NitroKit::SettingsSection.new(
          title: "Send recovery link",
          description: "Enter your account email. The response stays the same whether or not an account exists.",
          level: 5,
          id: "gallery-account-security-recovery-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, id: "gallery-account-security-recovery-error") do |alert|
              alert.title("Enter a valid email address")
              alert.description("Recovery was not requested and no account information was disclosed.")
            end
          elsif disabled
            section.status NitroKit::Alert.new(id: "gallery-account-security-recovery-loading") do |alert|
              alert.title("Requesting recovery")
              alert.description("The request is being checked against application rate limits.")
            end
          end
          section.form do
            form_with(url: "#recovery", scope: :recovery, builder: NitroKit::FormBuilder, id: "gallery-account-security-recovery-form") do |form|
              form.group do
                form.field(
                  :email,
                  as: :email,
                  label: "Account email",
                  value: invalid ? "missing-at-sign" : "ada@example.test",
                  errors: invalid ? [ "is invalid" ] : nil,
                  autocomplete: "email",
                  required: true,
                  disabled:
                )
                form.submit(
                  disabled ? "Requesting recovery…" : "Send recovery link",
                  id: "gallery-account-security-recovery-submit",
                  disabled:,
                  data: { turbo_submits_with: "Requesting recovery…" }
                )
              end
            end
          end
        end
      end

      def render_password_reset
        render NitroKit::SettingsSection.new(
          title: "Choose a new password",
          description: "Use 12 or more characters you do not use elsewhere.",
          level: 5,
          id: "gallery-account-security-reset-section"
        ) do |section|
          section.status NitroKit::Alert.new(variant: :warning, id: "gallery-account-security-reset-warning") do |alert|
            alert.title("All other sessions will be revoked")
            alert.description("Security keys and saved recovery codes remain enrolled.")
          end
          section.form do
            form_with(url: "#password-reset", scope: :password_reset, builder: NitroKit::FormBuilder, id: "gallery-account-security-reset-form") do |form|
              form.hidden_field(:token, value: "reset_4F8M")
              form.group do
                form.field(:password, as: :password, label: "New password", autocomplete: "new-password", value: nil, required: true)
                form.field(:password_confirmation, as: :password, label: "Confirm new password", autocomplete: "new-password", value: nil, required: true)
                form.submit("Reset password", id: "gallery-account-security-reset-submit")
              end
            end
          end
        end
      end

      def render_locked
        render NitroKit::Card.new(id: "gallery-account-security-locked-card") do |card|
          card.title("Account temporarily locked", level: 5)
          card.body do
            render NitroKit::Alert.new(variant: :error, id: "gallery-account-security-locked-alert") do |alert|
              alert.icon NitroKit::Icon.new(:lock_keyhole)
              alert.description("Too many sign-in attempts were rejected. Wait 15 minutes or request a signed unlock link.")
            end
          end
          card.footer do
            render NitroKit::ButtonGroup.new(label: "Locked account actions") do |actions|
              actions.button("Send unlock link", href: entry_path(entry, state: "unlock-sent"), variant: :primary, id: "gallery-account-security-unlock")
              actions.button("Use a recovery code", href: entry_path(entry, state: "recovery-code"))
            end
          end
        end
      end

      def render_two_factor
        invalid = state == "two-factor-invalid"

        render NitroKit::SettingsSection.new(
          title: "Enter authentication code",
          description: "Enter the current six-digit code from your authenticator app.",
          level: 5,
          id: "gallery-account-security-two-factor-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, id: "gallery-account-security-two-factor-error") do |alert|
              alert.title("Code was not accepted")
              alert.description("Enter the current six-digit code. One attempt remains before another temporary lock.")
            end
          end
          section.form do
            form_with(url: "#two-factor", scope: :two_factor, builder: NitroKit::FormBuilder, id: "gallery-account-security-two-factor-form") do |form|
              form.group do
                form.field(
                  :code,
                  label: "Six-digit authentication code",
                  value: invalid ? "12345" : nil,
                  errors: invalid ? [ "must contain six digits" ] : nil,
                  autocomplete: "one-time-code",
                  inputmode: "numeric",
                  pattern: "[0-9]{6}",
                  minlength: 6,
                  maxlength: 6,
                  required: true
                )
                form.submit("Verify identity", id: "gallery-account-security-two-factor-submit")
              end
            end
          end
        end
      end

      def render_recovery_code
        invalid = state == "recovery-code-invalid"

        render NitroKit::SettingsSection.new(
          title: "Use a recovery code",
          description: "Enter one saved single-use code. A successful code cannot be used again.",
          level: 5,
          id: "gallery-account-security-code-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, id: "gallery-account-security-code-error") do |alert|
              alert.title("Recovery code is invalid or already used")
              alert.description("No sign-in occurred. Try another saved code or contact an administrator.")
            end
          end
          section.form do
            form_with(url: "#recovery-code", scope: :recovery_code, builder: NitroKit::FormBuilder, id: "gallery-account-security-code-form") do |form|
              form.group do
                form.field(
                  :code,
                  label: "Recovery code",
                  value: invalid ? "USED-CODE" : nil,
                  errors: invalid ? [ "is invalid or already used" ] : nil,
                  autocomplete: "one-time-code",
                  required: true
                )
                form.submit("Use recovery code", id: "gallery-account-security-code-submit")
              end
            end
          end
        end
      end

      def render_trusted_device
        render NitroKit::SettingsSection.new(
          title: "Trust this browser",
          description: "Skip authentication codes on this browser for the next 30 days.",
          level: 5,
          id: "gallery-account-security-trust-section"
        ) do |section|
          section.status NitroKit::Alert.new(variant: :warning, id: "gallery-account-security-trust-warning") do |alert|
            alert.title("Use only on a private device")
            alert.description("Shared and managed public browsers should require authentication on every sign-in.")
          end
          section.form do
            form_with(url: "#trusted-device", scope: :trusted_device, builder: NitroKit::FormBuilder, id: "gallery-account-security-trust-form") do |form|
              form.group do
                form.field(:trusted, as: :checkbox, label: "Trust this browser for 30 days", checked: false)
                form.submit("Continue", id: "gallery-account-security-trust-submit")
              end
            end
          end
        end
      end

      def render_message(title, description, icon, action, href:)
        render NitroKit::EmptyState.new(
          title:,
          description:,
          level: 5,
          id: "gallery-account-security-message"
        ) do |empty|
          empty.icon NitroKit::Icon.new(icon)
          empty.action NitroKit::Button.new(action, href:, variant: :primary, id: "gallery-account-security-message-action")
        end
      end

      def render_long
        render NitroKit::Card.new(id: "gallery-account-security-long-card") do |card|
          card.title("Recover International Research, Production, Reliability, and Regulatory Archive administrator access", level: 5)
          card.body do
            p do
              "The recovery request was initiated for ada.lovelace+international-research-production-reliability@example.test " \
                "after several unsuccessful hardware-key challenges. No workspace membership, existing session, or enrolled factor is disclosed."
            end
          end
          card.footer do
            render NitroKit::Button.new("Continue recovery", href: entry_path(entry, state: "recovery-request"), variant: :primary)
          end
        end
      end

      def render_mobile
        render NitroKit::Card.new(id: "gallery-account-security-mobile-card") do |card|
          card.title("Verify identity", level: 5)
          card.body { "Use an authentication code or one saved recovery code on this narrow screen." }
          card.footer do
            render NitroKit::ButtonGroup.new(label: "Verification options") do |actions|
              actions.button("Authentication code", href: entry_path(entry, state: "two-factor-challenge"), variant: :primary)
              actions.button("Recovery code", href: entry_path(entry, state: "recovery-code"))
            end
          end
        end
      end

      def security_description
        {
          "recovery-request" => "Begin a discovery-safe recovery request.",
          "recovery-validation" => "Invalid input exposes no account state.",
          "recovery-sent" => "Delivery confirmation remains neutral and time-bound.",
          "reset" => "Choose a password and revoke other sessions.",
          "reset-expired" => "Expired tokens change nothing and lead to a new request.",
          "account-locked" => "Temporary lock information avoids disclosing active sessions.",
          "unlock-sent" => "Signed unlock instructions were requested.",
          "two-factor-challenge" => "Verify possession of an enrolled authenticator.",
          "two-factor-invalid" => "A rejected code preserves attempt context without exposing secrets.",
          "recovery-code" => "Use one saved single-use code.",
          "recovery-code-invalid" => "Rejected codes do not authenticate or reveal remaining codes.",
          "trusted-device" => "Make browser trust explicit after successful verification.",
          "loading" => "Mutation remains disabled while rate limits and delivery are checked.",
          "success" => "The safe next destination is explicit.",
          "long" => "Long account and organization copy stays readable.",
          "mobile" => "Recovery options remain distinct on a narrow surface."
        }.fetch(state)
      end

      def section_title = "Account recovery, locks, and two-factor authentication"
      def section_description = "Discovery-safe recovery, token expiry, account locks, authenticators, recovery codes, trusted devices, and pressure states."
    end
  end
end
