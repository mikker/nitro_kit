module Gallery
  module Compositions
    class AccountCreationPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        render_composition_header(eyebrow: "Registration")

        render Section.new(
          slug: "account-creation-screen",
          title: "Account creation",
          description: "Identity, credentials, consent, validation, submission, and post-registration verification."
        ) do
          render_example(
            slug: "account-creation-#{state}",
            title: state.to_s.humanize,
            description: state_description,
            mode: :full_width
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-account-creation-shell",
              aria: { label: "Nitro account creation" },
              data: {
                gallery: "composition-surface",
                gallery_composition: "account-creation",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              turbo_frame_tag("gallery-account-creation-frame") { render_screen }
            end
          end
        end
      end

      def render_screen
        render NitroKit::Card.new(id: "gallery-account-creation-card") do |card|
          card.title(state == "success" ? "Account created" : "Create your Nitro account", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              if state == "success"
                render_success
              else
                render_validation_summary if state == "validation"
                render_privacy_notice if state == "long-copy"
                render_form
              end
            end
          end
          card.divider
          card.footer do
            if state == "success"
              render NitroKit::Button.new(
                "Verify email address",
                id: "gallery-account-creation-verify",
                href: verification_path,
                variant: :primary
              )
            else
              p do
                plain "Already have an account? "
                a(href: sign_in_path) { "Sign in" }
              end
            end
          end
        end
      end

      def render_form
        account = Gallery::AuthFormExamples.account_creation(state == "validation" ? :invalid : :valid)
        disabled = state == "loading"

        form_with(
          model: account,
          url: "#account-creation",
          builder: NitroKit::FormBuilder,
          id: "gallery-account-creation-form",
          data: { turbo_frame: "gallery-account-creation-frame" }
        ) do |form|
          form.group do
            form.field(:name, label: "Full name", autocomplete: "name", required: true, disabled:)
            form.field(
              :email,
              as: :email,
              label: "Email address",
              description: "We will ask you to verify this address before onboarding.",
              autocomplete: "email",
              required: true,
              disabled:
            )
            form.field(
              :password,
              as: :password,
              label: "Password",
              description: "Use 12 or more characters.",
              autocomplete: "new-password",
              value: nil,
              required: true,
              disabled:
            )
            form.field(
              :terms,
              as: :checkbox,
              label: "I agree to the terms and privacy policy",
              required: true,
              disabled:
            )
            form.submit(
              disabled ? "Creating account…" : "Create account",
              id: "gallery-account-creation-submit",
              disabled:,
              data: { turbo_submits_with: "Creating account…" }
            )
          end
        end
      end

      def render_validation_summary
        render NitroKit::Alert.new(id: "gallery-account-creation-validation", variant: :error) do |alert|
          alert.title("Your account is not ready yet")
          alert.description("Correct the identity, email, password, and consent fields below.")
        end
      end

      def render_privacy_notice
        render NitroKit::Alert.new(id: "gallery-account-creation-privacy") do |alert|
          alert.title("How Nitro uses account information")
          alert.description do
            "Your name and email identify workspace activity, security notices, exports, and administrative audit " \
              "events. Nitro retains the minimum account data required to operate the service and will not use " \
              "workspace contact details for unrelated marketing without separate consent."
          end
        end
      end

      def render_success
        render NitroKit::Alert.new(id: "gallery-account-creation-success", variant: :success) do |alert|
          alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-account-creation-success-icon"))
          alert.title("Your account is ready")
          alert.description("Verify #{Gallery::Data.auth_identity.email} to continue to workspace setup.")
        end
      end

      def verification_path
        entry_path(Gallery::Catalog.fetch!(kind: :composition, slug: "email-verification"))
      end

      def sign_in_path
        entry_path(Gallery::Catalog.fetch!(kind: :composition, slug: "sign-in"))
      end

      def state_description
        {
          "default" => "A complete Rails form with identity, credentials, consent, and clear continuation.",
          "validation" => "Real Active Model errors connect summary copy to native controls.",
          "loading" => "Fields and primary action are disabled while Turbo submits.",
          "success" => "Registration hands off to email verification without losing the account address.",
          "long-copy" => "Specific privacy guidance wraps above the same unchanged form.",
          "mobile" => "A long email address and all required fields fit a narrow viewport."
        }.fetch(state)
      end
    end
  end
end
