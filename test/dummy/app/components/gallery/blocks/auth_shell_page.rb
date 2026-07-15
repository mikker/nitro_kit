module Gallery
  module Blocks
    class AuthShellPage < ComponentPage
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def source_note
        "app/components/nitro_kit/auth_shell.rb"
      end

      def api_note
        "NitroKit::AuthShell.new(id:, html:, aria:, data:, desperately_need_a_class:) { ... }"
      end

      def component_template
        example_section(
          "Application-owned content",
          slug: "auth-shell-content",
          description: "The shell supplies one semantic landmark, narrow constraint, gutters, and vertical rhythm. The application supplies every visible region."
        ) do
          example(
            "Credentials form",
            slug: "auth-shell-credentials",
            description: "A real Rails form and Card remain ordinary direct content."
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-auth-shell-credentials",
              aria: { label: "Credentials example" }
            ) do
              render_credentials_card
            end
          end

          example(
            "Caller-owned branding",
            slug: "auth-shell-branding",
            description: "Brand identity and supporting copy are siblings of the application-owned Card, not shell slots."
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-auth-shell-branding",
              aria: { labelledby: "gallery-auth-shell-brand-name" }
            ) do
              header(data: { gallery: "auth-branding" }) do
                h4(id: "gallery-auth-shell-brand-name") { "Analytical Engines" }
                p { "Secure workspace access for Research and Production." }
              end
              render_access_card
            end
          end

          example(
            "Caller-owned Turbo lifecycle",
            slug: "auth-shell-turbo",
            description: "The named Turbo Frame surrounds the shell and can replace the complete authentication state."
          ) do
            turbo_frame_tag("gallery-auth-shell-frame") do
              render NitroKit::AuthShell.new(
                id: "gallery-auth-shell-turbo",
                aria: { label: "Email verification status" }
              ) do
                render_verification_card
              end
            end
          end
        end

        example_section(
          "State and content pressure",
          slug: "auth-shell-pressure",
          description: "Validation, completion, long identity copy, and a deliberately narrow viewport all use the same optionless shell."
        ) do
          example(
            "Validation failure",
            slug: "auth-shell-validation",
            description: "Model errors, alert intent, field semantics, and recovery navigation remain caller-owned."
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-auth-shell-validation",
              aria: { label: "Invalid credentials example" }
            ) do
              render_validation_card
            end
          end

          example(
            "Successful handoff",
            slug: "auth-shell-success",
            description: "Completion content can replace the form without changing the shell contract."
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-auth-shell-success",
              aria: { label: "Successful sign-in example" }
            ) do
              render_success_card
            end
          end

          example(
            "Long account and workspace copy",
            slug: "auth-shell-long-copy",
            description: "Unbroken identity pressure shrinks inside the fixed medium content constraint."
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-auth-shell-long-copy",
              aria: { label: "Long account identity example" }
            ) do
              render_long_copy_card
            end
          end

          example(
            "Narrow mobile pressure",
            slug: "auth-shell-mobile",
            description: "Gallery viewport metadata narrows the same shell; Nitro keeps gutters and descendants shrinkable."
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-auth-shell-mobile",
              aria: { label: "Mobile authentication example" },
              data: { gallery: "flow-surface", gallery_mobile: "true" }
            ) do
              render_mobile_card
            end
          end
        end
      end

      def render_credentials_card
        credentials = Gallery::AuthFormExamples.sign_in(:valid)

        render NitroKit::Card.new(id: "gallery-auth-shell-credentials-card") do |card|
          card.title("Sign in to Nitro", level: 4)
          card.body do
            form_with(
              model: credentials,
              url: "#auth-shell-sign-in",
              builder: NitroKit::FormBuilder,
              id: "gallery-auth-shell-credentials-form"
            ) do |form|
              form.field(
                :email,
                as: :email,
                id: "gallery-auth-shell-credentials-email",
                label: "Email address",
                autocomplete: "email",
                required: true
              )
              form.field(
                :password,
                as: :password,
                id: "gallery-auth-shell-credentials-password",
                label: "Password",
                autocomplete: "current-password",
                required: true,
                value: nil
              )
              form.submit("Sign in", id: "gallery-auth-shell-credentials-submit")
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new("Forgot your password?", href: "#password-reset")
          end
        end
      end

      def render_access_card
        render NitroKit::Card.new(id: "gallery-auth-shell-branding-card") do |card|
          card.title("Welcome back", level: 4)
          card.body("Use your team account to continue to the workspace.")
          card.divider
          card.footer do
            render NitroKit::Button.new("Continue with email", href: "#email", variant: :primary)
          end
        end
      end

      def render_verification_card
        render NitroKit::Card.new(id: "gallery-auth-shell-verification-card") do |card|
          card.title("Check your inbox", level: 4)
          card.body do
            render NitroKit::Alert.new(id: "gallery-auth-shell-verification-alert") do |alert|
              alert.title("Verification pending")
              alert.description("We sent a secure link to ada@analytical-engines.example.test.")
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new("Resend verification", href: "#resend")
          end
        end
      end

      def render_validation_card
        credentials = Gallery::AuthFormExamples.sign_in(:invalid)

        render NitroKit::Card.new(id: "gallery-auth-shell-validation-card") do |card|
          card.title("Sign in to Nitro", level: 4)
          card.body do
            render NitroKit::Alert.new(id: "gallery-auth-shell-validation-alert", variant: :error) do |alert|
              alert.title("We could not sign you in")
              alert.description("Correct both fields below and try again.")
            end

            form_with(
              model: credentials,
              url: "#auth-shell-validation",
              builder: NitroKit::FormBuilder,
              id: "gallery-auth-shell-validation-form"
            ) do |form|
              form.field(
                :email,
                as: :email,
                id: "gallery-auth-shell-validation-email",
                label: "Email address",
                autocomplete: "email",
                required: true
              )
              form.field(
                :password,
                as: :password,
                id: "gallery-auth-shell-validation-password",
                label: "Password",
                autocomplete: "current-password",
                required: true,
                value: nil
              )
              form.submit("Try again", id: "gallery-auth-shell-validation-submit")
            end
          end
        end
      end

      def render_success_card
        render NitroKit::Card.new(id: "gallery-auth-shell-success-card") do |card|
          card.title("Welcome back", level: 4)
          card.body do
            render NitroKit::Alert.new(id: "gallery-auth-shell-success-alert", variant: :success) do |alert|
              alert.title("Sign-in complete")
              alert.description("Your secure session is ready for Analytical Engines.")
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new("Open workspace", href: "#workspace", variant: :primary)
          end
        end
      end

      def render_long_copy_card
        render NitroKit::Card.new(id: "gallery-auth-shell-long-copy-card") do |card|
          card.title("Verify your account", level: 4)
          card.body do
            p do
              "We sent instructions to katherine.johnson+analytical-engines-research-and-production@example.test " \
                "for the International Research, Production, and Reliability Engineering workspace."
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new("Use a different account", href: "#switch-account")
          end
        end
      end

      def render_mobile_card
        render NitroKit::Card.new(id: "gallery-auth-shell-mobile-card") do |card|
          card.title("Recover access", level: 4)
          card.body do
            render NitroKit::Alert.new(id: "gallery-auth-shell-mobile-alert", variant: :warning) do |alert|
              alert.title("This link expired")
              alert.description("Request a new link for your workspace account to continue securely.")
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new("Request another link", href: "#request", variant: :primary)
            render NitroKit::Button.new("Back to sign in", href: "#sign-in")
          end
        end
      end
    end
  end
end
