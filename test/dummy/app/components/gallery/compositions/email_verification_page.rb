module Gallery
  module Compositions
    class EmailVerificationPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        render_composition_header

        render Section.new(
          slug: "email-verification-screen",
          title: "Email verification",
          description: "Delivery, confirmation, token failure, and copy pressure stay explicit and recoverable."
        ) do
          render_example(
            slug: "email-verification-#{state}",
            title: humanize_state(state),
            description: state_description,
            mode: :full_width
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-email-verification-shell",
              aria: { label: "Nitro email verification" },
              data: {
                gallery: "composition-surface",
                gallery_composition: "email-verification"
              }
            ) do
              turbo_frame_tag("gallery-email-verification-frame") { render_screen }
            end
          end
        end
      end

      def render_screen
        render NitroKit::Card.new(id: "gallery-email-verification-card") do |card|
          card.title(screen_title, level: 4)
          card.body do
            render_status
          end
          card.divider
          card.footer { render_action }
        end
      end

      def render_status
        render NitroKit::Alert.new(
          id: "gallery-email-verification-alert",
          variant: alert_variant
        ) do |alert|
          alert.icon(NitroKit::Icon.new(alert_icon, id: "gallery-email-verification-alert-icon"))
          alert.description(alert_description)
        end
      end

      def render_action
        if state == "verified"
          render NitroKit::Button.new(
            "Continue to workspace",
            id: "gallery-email-verification-continue",
            href: "#workspace",
            variant: :primary
          )
        elsif state == "invalid-token"
          render NitroKit::Button.new(
            "Contact support",
            id: "gallery-email-verification-support",
            href: "mailto:support@example.test"
          )
        else
          verification = Gallery::AuthFormExamples.email_verification(state == "expired" ? :expired : :valid)
          form_with(
            model: verification,
            url: "#resend-verification",
            builder: NitroKit::FormBuilder,
            id: "gallery-email-verification-form",
            data: { turbo_frame: "gallery-email-verification-frame" }
          ) do |form|
            form.hidden_field(:token)
            form.group do
              form.submit(
                state == "expired" ? "Send a fresh link" : "Resend verification email",
                id: "gallery-email-verification-resend",
                data: { turbo_submits_with: "Sending…" }
              )
            end
          end
        end
      end

      def screen_title
        {
          "pending" => "Check your inbox",
          "verified" => "Email verified",
          "expired" => "Request a new verification link",
          "invalid-token" => "Verification link invalid",
          "long-copy" => "Check your inbox"
        }.fetch(state)
      end

      def alert_variant
        return :success if state == "verified"
        return :destructive if state == "invalid-token"
        return :warning if state == "expired"

        :default
      end

      def alert_icon
        {
          "pending" => :mail,
          "verified" => :circle_check,
          "expired" => :clock_alert,
          "invalid-token" => :circle_x,
          "long-copy" => :mail
        }.fetch(state)
      end

      def alert_description
        return invalid_token_message if state == "invalid-token"

        {
          "pending" => "We sent a verification link to #{Gallery::Data.auth_identity.email}.",
          "verified" => "Security notices and account recovery can now use #{Gallery::Data.auth_identity.email}.",
          "expired" => Gallery::AuthFormExamples.email_verification(:expired).errors.full_messages_for(:token).to_sentence,
          "long-copy" => "The address #{Gallery::Data.auth_identity.email} belongs to an account with several " \
            "forwarding rules. Delivery can take a few minutes. Check spam and quarantine folders before requesting " \
            "another message so older links do not become confusing."
        }.fetch(state)
      end

      def invalid_token_message
        verification = Gallery::AuthFormExamples.email_verification(:invalid)
        "#{verification.errors.full_messages_for(:token).to_sentence}. The link may already have been used."
      end

      def state_description
        {
          "pending" => "A resend action is scoped to the same Turbo frame.",
          "verified" => "A successful token exchange leaves one clear continuation.",
          "expired" => "Expired credentials can be replaced without contacting support.",
          "invalid-token" => "An invalid or already-used token explains the next support path.",
          "long-copy" => "Long addresses and operational guidance wrap without special component modes."
        }.fetch(state)
      end
    end
  end
end
