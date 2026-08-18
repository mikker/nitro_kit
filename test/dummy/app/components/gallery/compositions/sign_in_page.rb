module Gallery
  module Compositions
    class SignInPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        render_composition_header

        render Section.new(
          slug: "sign-in-screen",
          title: "Sign-in screen",
          description: "AuthShell constrains one model-backed Card while the composition retains credentials, recovery navigation, Turbo replacement, and submission pressure."
        ) do
          render_example(
            slug: "sign-in-#{state}",
            title: humanize_state(state),
            description: state_description,
            mode: :full_width
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-sign-in-shell",
              aria: {
                label: "Nitro account sign in",
                busy: state == "loading" ? "true" : nil
              }.compact,
              data: {
                gallery: "composition-surface",
                gallery_composition: "sign-in",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              turbo_frame_tag("gallery-sign-in-frame") { render_screen }
            end
          end
        end
      end

      def render_screen
        render NitroKit::Card.new(id: "gallery-sign-in-card") do |card|
          card.title(state == "success" ? "Welcome back" : "Sign in to Nitro", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              if state == "success"
                render_success
              else
                render_error if state == "invalid"
                render_form
              end
            end
          end
          card.divider
          card.footer do
            if state == "success"
              render NitroKit::Button.new(
                "Continue to workspace",
                id: "gallery-sign-in-continue",
                href: "#workspace",
                variant: :primary
              )
            else
              p do
                plain "New to Nitro? "
                a(href: entry_path(Gallery::Catalog.fetch!(kind: :composition, slug: "account-creation"))) do
                  "Create an account"
                end
              end
            end
          end
        end
      end

      def render_form
        credentials = Gallery::AuthFormExamples.sign_in(state == "invalid" ? :invalid : :valid)
        disabled = state == "loading"

        form_with(
          model: credentials,
          url: "#sign-in",
          builder: NitroKit::FormBuilder,
          id: "gallery-sign-in-form",
          data: { turbo_frame: "gallery-sign-in-frame" }
        ) do |form|
          form.group do
            form.field(
              :email,
              as: :email,
              label: "Email address",
              autocomplete: "email",
              required: true,
              disabled:
            )
            form.field(
              :password,
              as: :password,
              label: "Password",
              autocomplete: "current-password",
              required: true,
              disabled:,
              value: nil
            )
            form.field(
              :remember_me,
              as: :checkbox,
              label: "Keep me signed in on this device",
              disabled:
            )
            form.submit(
              disabled ? "Signing in…" : "Sign in",
              id: "gallery-sign-in-submit",
              disabled:,
              data: { turbo_submits_with: "Signing in…" }
            )
            a(href: entry_path(Gallery::Catalog.fetch!(kind: :composition, slug: "password-reset"))) do
              "Forgot your password?"
            end
          end
        end
      end

      def render_error
        render NitroKit::Alert.new(id: "gallery-sign-in-error", variant: :destructive) do |alert|
          alert.icon(NitroKit::Icon.new(:circle_x, id: "gallery-sign-in-error-icon"))
          alert.title("We could not sign you in")
          alert.description("Check the email and password below, then try again.")
        end
      end

      def render_success
        p(id: "gallery-sign-in-success") do
          "Your secure session is ready for Analytical Engines — Research and Production."
        end
      end

      def state_description
        {
          "default" => "Ready for credentials with recovery and account-creation paths.",
          "invalid" => "Real Active Model errors connect to both native controls.",
          "loading" => "Every mutable control and the submitting action are disabled.",
          "success" => "A completed Turbo-frame replacement with one clear next action.",
          "mobile" => "A long account address pressures a narrow mobile-width surface."
        }.fetch(state)
      end
    end
  end
end
