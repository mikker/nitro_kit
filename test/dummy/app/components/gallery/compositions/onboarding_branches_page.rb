module Gallery
  module Compositions
    class OnboardingBranchesPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      CompanyReview = ::Data.define(:branch, :workspace, :team_size, :region, :invitations, :integration)
      PersonalReview = ::Data.define(:branch, :workspace, :primary_use, :team)

      private

      def render_scenario
        workspace_surface do
          render_header
          render_branch_context

          case state
          when "choose-path" then render_path_choice
          when "company" then render_company_form
          when "solo" then render_solo_form
          when "import" then render_import_form
          when "invite-team" then render_invitation_form
          when "skip-team" then render_skipped("Team invitations skipped", "Invitations can be sent later from workspace members.", "integration")
          when "integration" then render_integration_choice
          when "skip-integration" then render_skipped("Integrations skipped", "The workspace will start without external delivery destinations.", "review-company")
          when "review-company" then render_review(:company)
          when "review-solo" then render_review(:solo)
          when "validation" then render_company_form(invalid: true)
          when "saving" then render_company_form(disabled: true)
          when "complete" then render_complete
          when "resume" then render_resume
          when "long" then render_long
          when "mobile" then render_mobile
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: onboarding_title,
          description: onboarding_description,
          level: 4,
          id: "gallery-onboarding-branches-header"
        ) do |header|
          unless %w[choose-path complete mobile].include?(state)
            header.actions NitroKit::ButtonGroup.new(label: "Onboarding session", id: "gallery-onboarding-branches-session") do |actions|
              actions.button("Save and exit", href: entry_path(entry, state: "resume"), disabled: state == "saving")
            end
          end
        end
      end

      def render_branch_context
        render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
          render NitroKit::Badge.new(
            branch_label,
            id: "gallery-onboarding-branches-context",
            color: branch_color,
            size: :sm
          )
        end
      end

      def render_path_choice
        render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-onboarding-branches-paths") do
          render_path_card("Company workspace", "Invite a team and connect delivery integrations.", "company", :building_2)
          render_path_card("Personal workspace", "Start alone with a minimal profile and no invitations.", "solo", :user)
          render_path_card("Import configuration", "Upload an application-owned export from another workspace.", "import", :upload)
        end
      end

      def render_path_card(title, description, destination, icon)
        render NitroKit::Card.new(id: "gallery-onboarding-path-#{destination}") do |card|
          card.title(title, level: 5)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Icon.new(icon)
              p { description }
            end
          end
          card.footer do
            render NitroKit::Button.new(
              "Choose #{title.downcase}",
              href: entry_path(entry, state: destination),
              id: "gallery-onboarding-path-#{destination}-action"
            )
          end
        end
      end

      def render_company_form(invalid: false, disabled: false)
        render NitroKit::SettingsSection.new(
          title: "Company details",
          description: "Choose the shared identity, expected size, and primary data region for this workspace.",
          level: 5,
          id: "gallery-onboarding-company-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, id: "gallery-onboarding-company-error") do |alert|
              alert.title("Workspace details were not saved")
              alert.description("Name the workspace, choose an allowed size, and accept the organization terms.")
            end
          elsif disabled
            section.status NitroKit::Alert.new(id: "gallery-onboarding-company-saving") do |alert|
              alert.title("Saving workspace")
              alert.description("The branch and every field remain visible while submission is disabled.")
            end
          end
          section.form do
            form_with(url: "#company-onboarding", scope: :company, builder: NitroKit::FormBuilder, id: "gallery-onboarding-company-form") do |form|
              form.group do
                form.field(
                  :workspace_name,
                  label: "Workspace name",
                  value: invalid ? "" : "Analytical Engines",
                  errors: invalid ? [ "cannot be blank" ] : nil,
                  required: true,
                  disabled:
                )
                form.field(
                  :team_size,
                  as: :select,
                  label: "Expected team size",
                  options: [ [ "Up to 5", "5" ], [ "Up to 20", "20" ], [ "Up to 50", "50" ] ],
                  value: invalid ? "" : "20",
                  errors: invalid ? [ "must be selected" ] : nil,
                  required: true,
                  disabled:
                )
                form.field(:region, as: :select, label: "Primary data region", options: [ [ "European Union", "eu" ], [ "United States", "us" ] ], value: "eu", required: true, disabled:)
                form.field(
                  :terms,
                  as: :checkbox,
                  label: "I can accept the organization terms",
                  checked: !invalid,
                  errors: invalid ? [ "must be accepted" ] : nil,
                  required: true,
                  disabled:
                )
                form.submit(
                  disabled ? "Saving workspace…" : "Continue to team",
                  id: "gallery-onboarding-company-submit",
                  disabled:,
                  data: { turbo_submits_with: "Saving workspace…" }
                )
              end
            end
          end
        end
      end

      def render_solo_form
        render NitroKit::SettingsSection.new(
          title: "Personal details",
          description: "Start with only the workspace identity and primary use you need today.",
          level: 5,
          id: "gallery-onboarding-solo-section"
        ) do |section|
          section.form do
            form_with(url: "#solo-onboarding", scope: :solo, builder: NitroKit::FormBuilder, id: "gallery-onboarding-solo-form") do |form|
              form.group do
                form.field(:workspace_name, label: "Workspace name", value: "Ada's research", required: true)
                form.field(:use_case, as: :select, label: "Primary use", options: [ [ "Personal projects", "personal" ], [ "Research", "research" ] ], value: "research", required: true)
                form.submit("Review personal workspace", id: "gallery-onboarding-solo-submit")
              end
            end
          end
        end
      end

      def render_import_form
        render NitroKit::SettingsSection.new(
          title: "Import configuration",
          description: "Upload an export from a workspace you trust. You can review every imported setting before creation.",
          level: 5,
          id: "gallery-onboarding-import-section"
        ) do |section|
          section.status NitroKit::Alert.new(variant: :warning, id: "gallery-onboarding-import-warning") do |alert|
            alert.title("Secrets are never imported")
            alert.description("The export may describe integrations, but credentials must be configured again.")
          end
          section.form do
            form_with(url: "#onboarding-import", scope: :workspace_import, builder: NitroKit::FormBuilder, id: "gallery-onboarding-import-form") do |form|
              form.group do
                form.dropzone(
                  :archive,
                  label: "Workspace export",
                  description: "Choose a JSON or ZIP export.",
                  direct_upload: false,
                  accept: ".json,.zip",
                  required: true
                )
                form.field(:confirm, as: :checkbox, label: "I reviewed the source workspace before export", required: true)
                form.submit("Validate import", id: "gallery-onboarding-import-submit")
              end
            end
          end
        end
      end

      def render_invitation_form
        render NitroKit::SettingsSection.new(
          title: "Invite teammates",
          description: "Add teammates now or skip this step and invite them after the workspace is ready.",
          level: 5,
          id: "gallery-onboarding-invite-section"
        ) do |section|
          section.form do
            form_with(url: "#onboarding-team", scope: :team, builder: NitroKit::FormBuilder, id: "gallery-onboarding-invite-form") do |form|
              form.group do
                form.field(:invitees, as: :textarea, label: "Email addresses", description: "One email address per line.", value: "grace@example.test\nkatherine@example.test")
                form.field(:default_role, as: :select, label: "Default role", options: [ [ "Member", "member" ], [ "Viewer", "viewer" ] ], value: "member", required: true)
                form.submit("Continue with invitations", id: "gallery-onboarding-invite-submit")
              end
            end
          end
        end
      end

      def render_skipped(title, description, destination)
        render NitroKit::Card.new(id: "gallery-onboarding-skipped-card") do |card|
          card.body do
            render NitroKit::EmptyState.new(
              title:,
              description:,
              variant: :borderless,
              level: 5,
              id: "gallery-onboarding-skipped-state"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:circle_check)
              empty.action NitroKit::Button.new("Continue", href: entry_path(entry, state: destination), variant: :primary)
              empty.action NitroKit::Button.new("Go back", href: entry_path(entry, state: state == "skip-team" ? "invite-team" : "integration"))
            end
          end
        end
      end

      def render_integration_choice
        render NitroKit::SettingsSection.new(
          title: "Delivery integrations",
          description: "Choose any integrations to configure after workspace creation, or continue without one.",
          level: 5,
          id: "gallery-onboarding-integrations-section"
        ) do |section|
          section.form do
            form_with(url: "#onboarding-integrations", scope: :integrations, builder: NitroKit::FormBuilder, id: "gallery-onboarding-integrations-form") do |form|
              form.group do
                render NitroKit::CheckboxGroup.new(
                  legend: "Integrations to configure",
                  description: "Credentials are added only after the workspace exists.",
                  options: [
                    { label: "GitHub", value: "github", description: "Repositories and deployments" },
                    { label: "Slack", value: "slack", description: "Incidents and release notifications" },
                    { label: "Webhook", value: "webhook", description: "An application-owned delivery endpoint" }
                  ],
                  name: "integrations[services]",
                  value: [ "github" ],
                  id: "gallery-onboarding-integrations-choices",
                  presentation: :cards
                )
                render NitroKit::Flex.new(dir: :row, gap: 2, align: :center, wrap: :wrap) do
                  form.submit("Continue to review", id: "gallery-onboarding-integrations-submit")
                  render NitroKit::Button.new("Skip integrations", href: entry_path(entry, state: "skip-integration"))
                end
              end
            end
          end
        end
      end

      def render_review(branch)
        record = review_record(branch)

        render NitroKit::DataSection.new(
          title: "Workspace summary",
          description: "Confirm these choices before the workspace is created.",
          level: 5,
          id: "gallery-onboarding-review-section"
        ) do |section|
          section.actions NitroKit::ButtonGroup.new(label: "Review actions") do |actions|
            actions.button("Create workspace", href: entry_path(entry, state: "saving"), variant: :primary)
            actions.button("Edit details", href: entry_path(entry, state: branch == :company ? "company" : "solo"))
          end
          section.table NitroKit::DetailsTable.new(
            record,
            label: "Onboarding choices",
            id: "gallery-onboarding-review-table"
          ) do |details|
            details.fields(*record.class.members)
          end
        end
      end

      def review_record(branch)
        if branch == :solo
          PersonalReview.new(branch: "Personal", workspace: "Ada's research", primary_use: "Research", team: "Skipped")
        else
          CompanyReview.new(
            branch: "Company",
            workspace: "Analytical Engines",
            team_size: "Up to 20",
            region: "European Union",
            invitations: "2 pending",
            integration: "GitHub after creation"
          )
        end
      end

      def render_complete
        render NitroKit::Card.new(id: "gallery-onboarding-complete-card") do |card|
          card.body do
            render NitroKit::EmptyState.new(
              title: "Workspace ready",
              description: "Analytical Engines was created. Invitations and integration setup continue independently.",
              variant: :borderless,
              level: 5,
              id: "gallery-onboarding-complete"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:circle_check)
              empty.action NitroKit::Button.new("Open workspace", href: "#workspace", variant: :primary, id: "gallery-onboarding-complete-action")
              empty.action NitroKit::Button.new("Configure integrations", href: "#integrations")
            end
          end
        end
      end

      def render_resume
        render NitroKit::Card.new(id: "gallery-onboarding-resume-card") do |card|
          card.title("Resume saved onboarding", level: 5)
          card.body do
            p { "Company branch · workspace details saved · team invitations not completed · saved July 13 at 10:48 UTC" }
          end
          card.footer do
            render NitroKit::ButtonGroup.new(label: "Resume actions") do |actions|
              actions.button("Resume team invitations", href: entry_path(entry, state: "invite-team"), variant: :primary)
              actions.button("Start over", href: entry_path(entry, state: "choose-path"))
            end
          end
        end
      end

      def render_long
        render NitroKit::Card.new(id: "gallery-onboarding-long-card") do |card|
          card.title("International Research, Production, Reliability, Regulatory Archive, and Customer Incident Coordination", level: 5)
          card.body do
            p { "118 expected members · European Union residency · 27 production environments · GitHub, Slack, and custom webhook setup deferred until administrator verification." }
          end
          card.footer do
            render NitroKit::Button.new("Continue review", href: entry_path(entry, state: "review-company"), variant: :primary)
          end
        end
      end

      def render_mobile
        render NitroKit::Card.new(id: "gallery-onboarding-mobile-card") do |card|
          card.title("Workspace type", level: 5)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 3, align: :stretch) do
              p { "Company, personal, and import setup stay separate on a narrow screen." }
              render NitroKit::Button.new("Company workspace", href: entry_path(entry, state: "company"), id: "gallery-onboarding-mobile-action")
              render NitroKit::Button.new("Personal workspace", href: entry_path(entry, state: "solo"))
              render NitroKit::Button.new("Import configuration", href: entry_path(entry, state: "import"))
            end
          end
        end
      end

      def branch_label
        return "Personal branch" if %w[solo review-solo].include?(state)
        return "Import branch" if state == "import"
        return "Choose branch" if state == "choose-path"

        "Company branch"
      end

      def branch_color
        { "Personal branch" => :info, "Import branch" => :warning, "Choose branch" => :neutral }.fetch(branch_label, :success)
      end

      def onboarding_title
        {
          "choose-path" => "Choose a setup path",
          "company" => "Set up a company workspace",
          "solo" => "Set up a personal workspace",
          "import" => "Import a workspace configuration",
          "invite-team" => "Build your team",
          "skip-team" => "Continue without invitations",
          "integration" => "Connect your tools",
          "skip-integration" => "Continue without integrations",
          "review-company" => "Review company workspace",
          "review-solo" => "Review personal workspace",
          "validation" => "Correct company details",
          "saving" => "Creating company workspace",
          "complete" => "Setup complete",
          "resume" => "Resume workspace setup",
          "long" => "Review company workspace",
          "mobile" => "Choose a setup path"
        }.fetch(state)
      end

      def onboarding_description
        {
          "choose-path" => "Choose a company, personal, or import branch without inventing one universal form.",
          "company" => "Collect organization details before team and integration choices.",
          "solo" => "Collect only the profile required for a personal workspace.",
          "import" => "Validate an application-owned export without importing secrets.",
          "invite-team" => "Invite a team or explicitly skip the optional step.",
          "skip-team" => "Preserve the branch decision and its safe return path.",
          "integration" => "Choose setup to perform after workspace creation.",
          "skip-integration" => "Continue without configuring external delivery.",
          "review-company" => "Review the complete company branch before creation.",
          "review-solo" => "Review the shorter personal branch before creation.",
          "validation" => "Keep invalid company details in their original branch.",
          "saving" => "Disable every mutation while preserving submitted context.",
          "complete" => "Name completed and deferred work separately.",
          "resume" => "Resume the exact saved branch and incomplete step.",
          "long" => "Long organization and operational context remains readable.",
          "mobile" => "Branch selection remains clear on a narrow surface."
        }.fetch(state)
      end

      def section_title = "Company, personal, and import onboarding branches"
      def section_description = "Branch choice, distinct forms, optional skips, review paths, resume state, validation, saving, and completion."
    end
  end
end
