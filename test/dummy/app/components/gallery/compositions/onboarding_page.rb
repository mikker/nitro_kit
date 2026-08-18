module Gallery
  module Compositions
    class OnboardingPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      private

      def page_template
        render_composition_header

        render Section.new(
          slug: "onboarding-screen",
          title: "Workspace onboarding",
          description: "Workspace, team, integration, review, resume, completion, validation, and loading states."
        ) do
          render_example(
            slug: "onboarding-#{state}",
            title: humanize_state(state),
            description: state_description,
            mode: :full_width
          ) do
            render NitroKit::AuthShell.new(
              id: "gallery-onboarding-shell",
              aria: {
                label: "Nitro workspace onboarding",
                busy: state == "loading" ? "true" : nil
              }.compact,
              data: {
                gallery: "composition-surface",
                gallery_composition: "onboarding",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              turbo_frame_tag("gallery-onboarding-frame") { render_screen }
            end
          end
        end
      end

      def render_screen
        render NitroKit::Card.new(id: "gallery-onboarding-card") do |card|
          card.title(screen_title, level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render_progress

              case state
              when "workspace", "workspace-validation"
                render_workspace_form
              when "team", "mobile"
                render_team_form
              when "integrations"
                render_integration_form
              when "review", "loading"
                render_review_form
              when "complete"
                render_complete
              when "resume"
                render_resume
              end
            end
          end
          card.divider
          card.footer { render_footer }
        end
      end

      def render_progress
        return if %w[complete resume].include?(state)

        render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
          render NitroKit::Badge.new(
            progress_label,
            id: "gallery-onboarding-progress",
            color: :info,
            size: :sm
          )
        end

        ol(data: { gallery: "composition-progress" }, aria: { label: "Onboarding progress" }) do
          Gallery::Data.onboarding_steps.each do |step|
            li(
              aria: { current: current_step.slug == step.slug ? "step" : nil },
              data: { complete: step.position < current_step.position ? "true" : nil }.compact
            ) { "#{step.position}. #{step.title}" }
          end
        end
      end

      def render_workspace_form
        invalid = state == "workspace-validation"
        onboarding = Gallery::AuthFormExamples.onboarding(invalid ? :invalid : :valid, step: "workspace")

        render_validation_summary(onboarding) if invalid
        form_with(
          model: onboarding,
          url: "#onboarding-workspace",
          builder: NitroKit::FormBuilder,
          id: "gallery-onboarding-workspace-form",
          data: { turbo_frame: "gallery-onboarding-frame" }
        ) do |form|
          form.group do
            form.field(
              :workspace_name,
              label: "Workspace name",
              description: "Teammates will see this name in navigation, invitations, and security notices.",
              required: true
            )
            form.field(
              :team_size,
              as: :select,
              label: "Expected team size",
              options: [ [ "Just me", 1 ], [ "2–5 people", 5 ], [ "6–20 people", 20 ], [ "21–50 people", 50 ] ],
              prompt: "Choose a range",
              required: true
            )
            form.submit(
              "Continue to team",
              id: "gallery-onboarding-workspace-submit",
              data: { turbo_submits_with: "Saving workspace…" }
            )
          end
        end
      end

      def render_team_form
        onboarding = Gallery::AuthFormExamples.onboarding(:valid, step: "team")

        form_with(
          model: onboarding,
          url: "#onboarding-team",
          builder: NitroKit::FormBuilder,
          id: "gallery-onboarding-team-form",
          data: { turbo_frame: "gallery-onboarding-frame" }
        ) do |form|
          form.group do
            form.field(
              :invitees,
              as: :textarea,
              label: "Teammate email addresses",
              description: "Enter one address per line. Invitations are sent after you confirm the workspace.",
              placeholder: "grace@example.test\nkatherine@example.test"
            )
            form.submit(
              "Continue to integrations",
              id: "gallery-onboarding-team-submit",
              data: { turbo_submits_with: "Saving invitations…" }
            )
          end
        end
      end

      def render_integration_form
        onboarding = Gallery::AuthFormExamples.onboarding(:valid, step: "integrations")

        form_with(
          model: onboarding,
          url: "#onboarding-integrations",
          builder: NitroKit::FormBuilder,
          id: "gallery-onboarding-integrations-form",
          data: { turbo_frame: "gallery-onboarding-frame" }
        ) do |form|
          form.group do
            form.field(
              :integration,
              as: :radio_group,
              label: "First integration",
              description: "You can connect more tools after setup.",
              options: [
                [ "GitHub — repositories and deployments", "github" ],
                [ "Slack — notifications and approvals", "slack" ],
                [ "Skip for now", "none" ]
              ],
              required: true
            )
            form.submit(
              "Review setup",
              id: "gallery-onboarding-integrations-submit",
              data: { turbo_submits_with: "Saving integration…" }
            )
          end
        end
      end

      def render_review_form
        onboarding = Gallery::AuthFormExamples.onboarding(:valid, step: "review")
        disabled = state == "loading"

        render NitroKit::DetailsTable.new(
          onboarding,
          data: { gallery: "composition-summary" }
        ) do |details|
          details.field(:workspace_name, label: "Workspace")
          details.field(:team_size) { |size| plain "Up to #{size} people" }
          details.field(:invitee_emails, label: "Invitations") { |emails| plain emails.to_sentence }
          details.field(:integration) { |integration| plain integration.humanize }
        end

        form_with(
          model: onboarding,
          url: "#onboarding-complete",
          builder: NitroKit::FormBuilder,
          id: "gallery-onboarding-review-form",
          data: { turbo_frame: "gallery-onboarding-frame" }
        ) do |form|
          form.group do
            form.field(
              :terms,
              as: :checkbox,
              label: "I confirm this workspace setup",
              required: true,
              disabled:
            )
            form.submit(
              disabled ? "Creating workspace…" : "Create workspace",
              id: "gallery-onboarding-review-submit",
              disabled:,
              data: { turbo_submits_with: "Creating workspace…" }
            )
          end
        end
      end

      def render_complete
        render NitroKit::Alert.new(id: "gallery-onboarding-complete", variant: :success) do |alert|
          alert.icon(NitroKit::Icon.new(:party_popper, id: "gallery-onboarding-complete-icon"))
          alert.description do
            "#{Gallery::Data.auth_identity.workspace} is ready with two pending invitations and GitHub connected."
          end
        end
      end

      def render_resume
        render NitroKit::Alert.new(id: "gallery-onboarding-resume", variant: :warning) do |alert|
          alert.icon(NitroKit::Icon.new(:clock_3, id: "gallery-onboarding-resume-icon"))
          alert.description("Workspace details and team invitations were saved on July 13, 2026 at 09:15 UTC.")
        end
      end

      def render_validation_summary(onboarding)
        render NitroKit::Alert.new(id: "gallery-onboarding-validation", variant: :destructive) do |alert|
          alert.title("Workspace details need attention")
          alert.description(onboarding.errors.full_messages.to_sentence)
        end
      end

      def render_footer
        case state
        when "complete"
          render NitroKit::Button.new(
            "Open workspace",
            id: "gallery-onboarding-open-workspace",
            href: "#workspace",
            variant: :primary
          )
        when "resume"
          render NitroKit::Button.new(
            "Continue setup",
            id: "gallery-onboarding-resume-setup",
            href: entry_path(entry, state: "integrations"),
            variant: :primary
          )
        else
          render NitroKit::Button.new(
            "Save and finish later",
            id: "gallery-onboarding-save-later",
            href: entry_path(entry, state: "resume")
          )
        end
      end

      def current_step
        slug = {
          "workspace" => "workspace",
          "workspace-validation" => "workspace",
          "team" => "team",
          "mobile" => "team",
          "integrations" => "integrations",
          "review" => "review",
          "loading" => "review"
        }.fetch(state)

        Gallery::Data.onboarding_steps.find { |step| step.slug == slug }
      end

      def screen_title
        return "Workspace ready" if state == "complete"
        return "Resume workspace setup" if state == "resume"

        current_step.title
      end

      def progress_label
        return "Complete" if state == "complete"
        return "Saved at step 3 of 4" if state == "resume"

        "Step #{current_step.position} of #{Gallery::Data.onboarding_steps.length}"
      end

      def state_description
        {
          "workspace" => "Step one collects the shared workspace identity and expected scale.",
          "workspace-validation" => "Real validation rejects missing identity and an unsupported size.",
          "team" => "Step two accepts an optional newline-delimited invitation list.",
          "integrations" => "Step three uses a native required radio fieldset.",
          "review" => "Step four summarizes deterministic state before required confirmation.",
          "loading" => "Final confirmation and submission stay visible but disabled.",
          "complete" => "Completion summarizes exactly what was created.",
          "resume" => "A saved setup records where and when the user can continue.",
          "mobile" => "Long invitation addresses stress the team step at mobile width."
        }.fetch(state)
      end
    end
  end
end
