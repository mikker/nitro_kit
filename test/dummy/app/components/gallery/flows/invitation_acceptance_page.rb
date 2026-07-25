module Gallery
  module Flows
    class InvitationAcceptancePage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        header(data: { gallery: "flow-header" }) do
          p(data: { gallery: "eyebrow" }) { "Invitation flow" }
          h1 { entry.title }
          p { entry.description }
          state_navigation
        end

        render Section.new(
          slug: "invitation-acceptance-screen",
          title: "Invitation acceptance",
          description: "Workspace context, identity setup, consent, token recovery, and narrow-screen stress."
        ) do
          render_example(
            slug: "invitation-acceptance-#{state}",
            title: state.to_s.humanize,
            description: state_description,
            mode: :full_width
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-invitation-shell",
              aria: { label: "Nitro invitation acceptance" },
              data: {
                gallery: "flow-surface",
                gallery_flow: "invitation-acceptance",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              turbo_frame_tag("gallery-invitation-frame") { render_screen }
            end
          end
        end
      end

      def render_screen
        identity = Gallery::Data.auth_identity

        render NitroKit::Card.new(id: "gallery-invitation-card") do |card|
          card.title(card_title, level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              p do
                "#{identity.inviter} invited #{identity.email} to join as #{identity.invited_role.downcase}."
              end

              case state
              when "accepted"
                render_accepted
              when "expired", "invalid-token"
                render_token_error
              else
                render_validation_summary if state == "validation"
                render_form
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::Badge.new(
              identity.invited_role,
              id: "gallery-invitation-role",
              color: :info,
              size: :sm
            )
            small { "Invited #{identity.invited_at.utc.strftime("%B %-d, %Y at %H:%M UTC")}" }
            render_recovery_action if %w[accepted expired invalid-token].include?(state)
          end
        end
      end

      def render_form
        invitation = Gallery::AuthFormExamples.invitation(state == "validation" ? :invalid : :valid)
        disabled = state == "loading"

        form_with(
          model: invitation,
          url: "#accept-invitation",
          builder: NitroKit::FormBuilder,
          id: "gallery-invitation-form",
          data: { turbo_frame: "gallery-invitation-frame" }
        ) do |form|
          form.hidden_field(:token)
          form.group do
            form.field(
              :name,
              label: "Your name",
              autocomplete: "name",
              required: true,
              disabled:
            )
            form.field(
              :password,
              as: :password,
              label: "Create a password",
              description: "Use at least 12 characters.",
              autocomplete: "new-password",
              value: nil,
              required: true,
              disabled:
            )
            form.field(
              :terms,
              as: :checkbox,
              label: "I agree to the terms and workspace access policy",
              required: true,
              disabled:
            )
            form.submit(
              disabled ? "Joining workspace…" : "Accept invitation",
              id: "gallery-invitation-submit",
              disabled:,
              data: { turbo_submits_with: "Joining workspace…" }
            )
          end
        end
      end

      def render_validation_summary
        render NitroKit::Alert.new(id: "gallery-invitation-validation", variant: :error) do |alert|
          alert.title("Complete the highlighted details")
          alert.description("Your name, a secure password, and acceptance of the access policy are required.")
        end
      end

      def render_accepted
        render NitroKit::Alert.new(id: "gallery-invitation-accepted", variant: :success) do |alert|
          alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-invitation-accepted-icon"))
          alert.title("Invitation accepted")
          alert.description("Your administrator access is ready. You can continue to workspace onboarding.")
        end
      end

      def render_token_error
        example_state = state == "expired" ? :expired : :invalid_token
        invitation = Gallery::AuthFormExamples.invitation(example_state)

        render NitroKit::Alert.new(
          id: "gallery-invitation-token-error",
          variant: state == "expired" ? :warning : :error
        ) do |alert|
          alert.icon(NitroKit::Icon.new(:circle_x, id: "gallery-invitation-token-error-icon"))
          alert.title(state == "expired" ? "This invitation expired" : "This invitation is not valid")
          alert.description(invitation.errors.full_messages_for(:token).to_sentence)
        end
      end

      def render_recovery_action
        text, href, variant = if state == "accepted"
          [ "Start onboarding", onboarding_path, :primary ]
        else
          [ "Ask for a new invitation", "mailto:ada@example.test", :default ]
        end

        render NitroKit::Button.new(
          text,
          id: "gallery-invitation-recovery",
          href:,
          variant:
        )
      end

      def card_title
        return "You joined #{Gallery::Data.auth_identity.workspace}" if state == "accepted"

        "Join #{Gallery::Data.auth_identity.workspace}"
      end

      def onboarding_path
        entry_path(Gallery::Catalog.fetch!(kind: :flow, slug: "onboarding"))
      end

      def state_description
        {
          "valid" => "A valid token carries workspace and role context into account setup.",
          "validation" => "Real form errors cover identity, password, and required consent.",
          "loading" => "All mutable fields and the primary action are disabled during submission.",
          "accepted" => "Success preserves workspace context and points to onboarding.",
          "expired" => "An expired invitation offers a human recovery path.",
          "invalid-token" => "A forged or already-used token cannot reveal account details.",
          "mobile" => "Long workspace and account names pressure a narrow composition."
        }.fetch(state)
      end

      def state_navigation
        nav(aria: { label: "Invitation acceptance states" }, data: { gallery: "flow-states" }) do
          entry.states.each do |name|
            a(href: entry_path(entry, state: name), aria: { current: state == name ? "page" : nil }) do
              name.humanize
            end
          end
        end
      end
    end
  end
end
