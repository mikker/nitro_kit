module Gallery
  module Flows
    class PasswordResetPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        header(data: { gallery: "flow-header" }) do
          p(data: { gallery: "eyebrow" }) { "Recovery flow" }
          h1 { entry.title }
          p { entry.description }
          state_navigation
        end

        render Section.new(
          slug: "password-reset-screen",
          title: "Password recovery",
          description: "AuthShell constrains request, delivery, replacement, expiration, and submission states while the flow keeps its deterministic Turbo route."
        ) do
          render_example(
            slug: "password-reset-#{state}",
            title: state.to_s.humanize,
            description: state_description,
            mode: :full_width
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-password-reset-shell",
              aria: { label: "Nitro password recovery" },
              data: { gallery: "flow-surface", gallery_flow: "password-reset" }
            ) do
              turbo_frame_tag("gallery-password-reset-frame") { render_screen }
            end
          end
        end
      end

      def render_screen
        render NitroKit::Card.new(id: "gallery-password-reset-card") do |card|
          card.title(screen_title, level: 4)
          card.body do
            render NitroKit::VStack.new(gap: :md, align: :stretch) do
              case state
              when "sent"
                render_sent
              when "expired"
                render_expired
              when "update"
                render_update_form
              else
                render_request_error if state == "validation"
                render_request_form
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new(
              state == "expired" ? "Request a new link" : "Back to sign in",
              id: "gallery-password-reset-secondary",
              href: state == "expired" ? entry_path(entry, state: "request") : sign_in_path,
              variant: state == "expired" ? :primary : :ghost
            )
          end
        end
      end

      def render_request_form
        reset = Gallery::AuthFormExamples.password_reset(state == "validation" ? :request_invalid : :request)
        disabled = state == "loading"

        form_with(
          model: reset,
          url: "#password-reset",
          builder: NitroKit::FormBuilder,
          id: "gallery-password-reset-request-form",
          data: { turbo_frame: "gallery-password-reset-frame" }
        ) do |form|
          p { "Enter the email attached to your account. We will send a link that expires after 30 minutes." }
          form.field(
            :email,
            as: :email,
            label: "Account email",
            autocomplete: "email",
            required: true,
            disabled:
          )
          form.submit(
            disabled ? "Sending link…" : "Send reset link",
            id: "gallery-password-reset-submit",
            disabled:,
            data: { turbo_submits_with: "Sending link…" }
          )
        end
      end

      def render_update_form
        reset = Gallery::AuthFormExamples.password_reset(:update)

        form_with(
          model: reset,
          url: "#password-update",
          builder: NitroKit::FormBuilder,
          id: "gallery-password-reset-update-form",
          data: { turbo_frame: "gallery-password-reset-frame" }
        ) do |form|
          form.hidden_field(:token)
          form.field(
            :password,
            as: :password,
            label: "New password",
            description: "Use 12 or more characters you do not use elsewhere.",
            autocomplete: "new-password",
            value: nil,
            required: true
          )
          form.field(
            :password_confirmation,
            as: :password,
            label: "Confirm new password",
            autocomplete: "new-password",
            value: nil,
            required: true
          )
          form.submit(
            "Update password",
            id: "gallery-password-update-submit",
            data: { turbo_submits_with: "Updating password…" }
          )
        end
      end

      def render_request_error
        render NitroKit::Alert.new(id: "gallery-password-reset-error", variant: :error) do |alert|
          alert.title("Enter a valid email address")
          alert.description("The reset link cannot be delivered until the address is corrected.")
        end
      end

      def render_sent
        render NitroKit::Alert.new(id: "gallery-password-reset-sent", variant: :success) do |alert|
          alert.icon(NitroKit::Icon.new(:mail_check, id: "gallery-password-reset-sent-icon"))
          alert.title("Check your inbox")
          alert.description do
            "We sent a recovery link to #{Gallery::Data.auth_identity.email}. " \
              "For security, the page looks the same even when an account does not exist."
          end
        end
      end

      def render_expired
        reset = Gallery::AuthFormExamples.password_reset(:expired)

        render NitroKit::Alert.new(id: "gallery-password-reset-expired", variant: :warning) do |alert|
          alert.icon(NitroKit::Icon.new(:clock_alert, id: "gallery-password-reset-expired-icon"))
          alert.title("This reset link has expired")
          alert.description(reset.errors.full_messages_for(:token).to_sentence)
        end
      end

      def screen_title
        {
          "request" => "Reset your password",
          "validation" => "Reset your password",
          "sent" => "Email sent",
          "update" => "Choose a new password",
          "expired" => "Link expired",
          "loading" => "Reset your password"
        }.fetch(state)
      end

      def state_description
        {
          "request" => "A security-conscious request form that does not disclose account existence.",
          "validation" => "A malformed address produces a real model error and summary.",
          "sent" => "Success copy tolerates a deliberately long account address.",
          "update" => "The token stays hidden while replacement fields advertise new-password autocomplete.",
          "expired" => "An unusable token offers recovery instead of a dead end.",
          "loading" => "The address and submit action are disabled while Turbo submits."
        }.fetch(state)
      end

      def state_navigation
        nav(aria: { label: "Password reset states" }, data: { gallery: "flow-states" }) do
          entry.states.each do |name|
            a(href: entry_path(entry, state: name), aria: { current: state == name ? "page" : nil }) do
              name.humanize
            end
          end
        end
      end

      def sign_in_path
        entry_path(Gallery::Catalog.fetch!(kind: :flow, slug: "sign-in"))
      end
    end
  end
end
