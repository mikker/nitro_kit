module Gallery
  module Compositions
    class InvitationAcceptancePage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        render_composition_header

        render Section.new(
          slug: "invitation-acceptance-screen",
          title: "Invitation acceptance",
          description: "Workspace context, identity setup, consent, token recovery, and narrow-screen stress."
        ) do
          render_example(
            slug: "invitation-acceptance-#{state}",
            title: humanize_state(state),
            description: state_description,
            mode: :full_width
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-invitation-shell",
              aria: {
                label: "Nitro invitation acceptance",
                busy: state == "loading" ? "true" : nil
              }.compact,
              data: {
                gallery: "composition-surface",
                gallery_composition: "invitation-acceptance",
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
              render_invitation_context(identity)

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
          if %w[accepted expired invalid-token].include?(state)
            card.divider
            card.footer { render_recovery_action }
          end
        end
      end

      def render_invitation_context(identity)
        p { "#{identity.inviter} invited #{identity.email} to this workspace." }
        render NitroKit::Flex.new(
          dir: "col sm:row",
          gap: 2,
          align: "start sm:center",
          wrap: :wrap
        ) do
          render NitroKit::Badge.new(
            identity.invited_role,
            id: "gallery-invitation-role",
            color: :info,
            size: :sm
          )
          small { "Invited #{identity.invited_at.utc.strftime("%B %-d, %Y at %H:%M UTC")}" }
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
        render NitroKit::Alert.new(id: "gallery-invitation-validation", variant: :destructive) do |alert|
          alert.title("Complete the highlighted details")
          alert.description("Your name, a secure password, and acceptance of the access policy are required.")
        end
      end

      def render_accepted
        render NitroKit::Alert.new(id: "gallery-invitation-accepted", variant: :success) do |alert|
          alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-invitation-accepted-icon"))
          alert.description("Your administrator access is ready. Continue to workspace onboarding when you are ready.")
        end
      end

      def render_token_error
        example_state = state == "expired" ? :expired : :invalid_token
        invitation = Gallery::AuthFormExamples.invitation(example_state)

        render NitroKit::Alert.new(
          id: "gallery-invitation-token-error",
          variant: state == "expired" ? :warning : :destructive
        ) do |alert|
          alert.icon(
            NitroKit::Icon.new(
              state == "expired" ? :clock_alert : :circle_x,
              id: "gallery-invitation-token-error-icon"
            )
          )
          alert.description(invitation.errors.full_messages_for(:token).to_sentence)
        end
      end

      def render_recovery_action
        text, href, variant = if state == "accepted"
          [ "Start onboarding", onboarding_path, :primary ]
        else
          [ "Ask for a new invitation", "mailto:ada@example.test", nil ]
        end

        render NitroKit::Button.new(
          text,
          id: "gallery-invitation-recovery",
          href:,
          **{ variant: }.compact
        )
      end

      def card_title
        return "Invitation accepted" if state == "accepted"
        return "Invitation expired" if state == "expired"
        return "Invitation not valid" if state == "invalid-token"

        "Join #{Gallery::Data.auth_identity.workspace}"
      end

      def onboarding_path
        entry_path(Gallery::Catalog.fetch!(kind: :composition, slug: "onboarding"))
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
    end
  end
end
