module Gallery
  module Compositions
    class HelpCenterPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      SupportRequest = ::Data.define(:category, :priority, :submitted)

      private

      def render_scenario
        workspace_surface do
          render_header

          case state
          when "faq", "long", "mobile"
            render_search
            render_faq
          when "search", "empty"
            render_search
            render_search_results
          when "contact", "contact-validation"
            render_contact
          when "contact-sent"
            render_contact_sent
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: help_title,
          description: state_description,
          id: "gallery-help-center-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(id: "gallery-help-center-header-actions", label: "Help center navigation")
          ) do |actions|
            if state.in?(%w[contact contact-validation contact-sent])
              actions.button("Browse help", href: entry_path(entry, state: "faq"), icon: :arrow_left)
            else
              actions.button("Contact support", href: entry_path(entry, state: "contact"), variant: :primary, icon: :messages_square)
            end
          end
        end
      end

      def render_search
        form_with(model: help_search, scope: :help, url: entry_path(entry, state: "search"), method: :get, builder: NitroKit::FormBuilder, id: "gallery-help-center-search-form") do |form|
          form.fieldset(legend: "Search help articles", html: { id: "gallery-help-center-search-section" }) do
            form.group do
              render NitroKit::Grid.new(cols: "1 md:3", gap: 3) do
                form.field(:query, as: :search, label: "Question or keyword", placeholder: "Uploads, integrations, billing, or security", autocomplete: "off")
                form.field(
                  :category,
                  as: :select,
                  label: "Category",
                  options: Gallery::Forms::HelpSearch::CATEGORIES.map { |category| [ category.humanize, category ] }
                )
                render NitroKit::Flex.new(dir: :row, gap: 2, align: :end, justify: :end, wrap: :wrap) do
                  if help_search.query.present? || help_search.category != "all"
                    render NitroKit::Button.new("Clear", href: entry_path(entry, state: "faq"))
                  end
                  form.submit("Search help", id: "gallery-help-center-search-submit")
                end
              end
            end
          end
        end
      end

      def render_faq
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-help-center-faq-card") do
          h2 { "Frequently asked questions" }
          p { "Start with the questions teams ask most often." }
          render NitroKit::Accordion.new(id: "gallery-help-center-faq", mode: :single) do |accordion|
            questions.each_with_index do |question, index|
              accordion.item(question.id, title: faq_question(question, index), expanded: index.zero?) do
                render NitroKit::Typeset.new do
                  p { question.answer }
                  p { small { "Category: #{question.category.to_s.humanize}" } }
                end
              end
            end
          end
          render NitroKit::Toolbar.new do |toolbar|
            toolbar.trailing do
              render NitroKit::Button.new("Ask another question", href: entry_path(entry, state: "contact"), id: "gallery-help-center-faq-contact")
            end
          end
        end
      end

      def render_search_results
        render NitroKit::DataSection.new(
          title: "Help results",
          description: "Articles matching the current keyword and category appear below.",
          id: "gallery-help-center-results-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-help-center-results-actions", label: "Help result actions")
          ) do |actions|
            actions.button("Clear search", href: entry_path(entry, state: "faq"))
          end

          if questions.empty?
            section.empty_state NitroKit::EmptyState.new(
              title: "No help articles match this search",
              description: "Try another keyword or send the support team a detailed question.",
              variant: :borderless,
              level: 3,
              id: "gallery-help-center-empty"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:search_x, id: "gallery-help-center-empty-icon")
              empty.action NitroKit::Button.new(
                "Contact support",
                href: entry_path(entry, state: "contact"),
                variant: :primary,
                id: "gallery-help-center-empty-contact"
              )
            end
          else
            section.table NitroKit::Table.new(id: "gallery-help-center-results-table") do |table|
              table.caption("Help articles matching the current query")
              table.thead do
                table.tr do
                  table.th("Question")
                  table.th("Category")
                  table.th("Action", align: :right)
                end
              end
              table.tbody do
                questions.each do |question|
                  table.tr do
                    table.th(question.question, scope: :row)
                    table.td(question.category.to_s.humanize)
                    table.td(align: :right) do
                      render NitroKit::Button.new(
                        "Read answer",
                        href: "##{question.id}",
                        size: :sm,
                        aria: { label: "Read answer: #{question.question}" }
                      )
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_contact
        invalid = state == "contact-validation"
        contact = help_contact(invalid:)

        render NitroKit::SettingsSection.new(
          title: "Send a support request",
          description: "Share enough context for the support team to reproduce the issue. We usually reply within one business day.",
          id: "gallery-help-center-contact-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, id: "gallery-help-center-contact-error") do |alert|
              alert.title("Your support request needs attention")
              alert.description("Provide a valid email, category, subject, and a message of at least 20 characters.")
            end
          end
          section.form do
            form_with(
              model: contact,
              url: "#support-requests",
              builder: NitroKit::FormBuilder,
              id: "gallery-help-center-contact-form"
            ) do |form|
              form.fieldset(
                legend: "Support request",
                description: "Do not include passwords, API credentials, recovery codes, or payment card details."
              ) do
                form.group do
                  form.field(:email, as: :email, label: "Reply email", autocomplete: "email", required: true)
                  form.field(
                    :category,
                    as: :select,
                    label: "Category",
                    options: Gallery::Forms::HelpContact::CATEGORIES.map { |category| [ category.humanize, category ] },
                    prompt: "Choose a category",
                    required: true
                  )
                  form.field(:subject, label: "Subject", required: true, maxlength: 120)
                  form.field(
                    :message,
                    as: :textarea,
                    label: "How can we help?",
                    required: true,
                    minlength: 20, maxlength: 2_000
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-help-center-contact-toolbar") do |toolbar|
                toolbar.trailing do
                  form.submit(
                    "Send support request",
                    id: "gallery-help-center-contact-submit",
                    data: { turbo_submits_with: "Sending request…" }
                  )
                end
              end
            end
          end
        end
      end

      def render_contact_sent
        render NitroKit::Flex.new(dir: :col, gap: 5, align: :stretch, id: "gallery-help-center-contact-sent-card") do
          render NitroKit::Alert.new(variant: :success, live: :polite, id: "gallery-help-center-contact-sent") do |alert|
            alert.icon NitroKit::Icon.new(:circle_check, id: "gallery-help-center-contact-sent-icon")
            alert.title("Request SUP-2048 was created")
            alert.description("A reply will be sent to ada@example.test within one business day.")
          end
          render NitroKit::DetailsTable.new(support_request, caption: "Support request summary", data: { gallery: "support-request-metadata" }) do |details|
            details.fields(:category, :priority, :submitted)
          end
          render NitroKit::Toolbar.new do |toolbar|
            toolbar.trailing do
              render NitroKit::Button.new("Return to help center", href: entry_path(entry, state: "faq"), variant: :primary, id: "gallery-help-center-contact-sent-return")
            end
          end
        end
      end

      def help_search
        @help_search ||= begin
          attributes = case state
          when "search"
            { query: "upload", category: "data" }
          when "empty"
            { query: "unsupported mainframe quantum teleprinter", category: "billing" }
          else
            { query: nil, category: "all" }
          end
          Gallery::Forms::HelpSearch.new(attributes)
        end
      end

      def support_request
        SupportRequest.new(category: "Integrations", priority: "Normal", submitted: "July 13, 2026 at 09:44 UTC")
      end

      def help_contact(invalid:)
        attributes = invalid ?
          { email: "invalid", category: "unknown", subject: "", message: "Too short" } :
          {
            email: "ada@example.test",
            category: "integrations",
            subject: "Slack notifications stopped after authorization refresh",
            message: "Production incident notifications stopped after we refreshed the Slack authorization grant."
          }

        Gallery::Forms::HelpContact.new(**attributes).tap { |contact| contact.validate if invalid }
      end

      def questions
        @questions ||= begin
          records = Gallery::OperationalData.help_questions
          case state
          when "search"
            records.select { |question| question.category == :data && question.question.downcase.include?("upload") }
          when "empty"
            []
          when "mobile"
            records.first(3)
          else
            records
          end
        end
      end

      def faq_question(question, index)
        return question.question unless state == "long" && index.zero?

        "Which files can International Research, Production, Reliability Engineering, Regulatory Operations, and Customer Operations upload?"
      end

      def help_title
        return "Help for Analytical Engines — International Research, Production, Reliability Engineering, and Customer Operations" if state == "long"
        return "Contact support" if state.in?(%w[contact contact-validation contact-sent])

        "Help center"
      end

      def section_title = "Help center, FAQ, and contact"
      def section_description = "FAQ, search, zero-result, support form, validation, outcome, long-content, and narrow states."

      def state_description
        {
          "faq" => "Find practical answers for uploads, integrations, billing, and workspace security.",
          "search" => "One data article matches “upload” in the current help collection.",
          "empty" => "No billing article matches this search, but the support team can still help.",
          "contact" => "Tell us what happened and where to send the reply.",
          "contact-validation" => "A few details are missing or invalid. Your message has been preserved.",
          "contact-sent" => "Your request is in the queue and a reply will arrive within one business day.",
          "long" => "Find guidance for large research, production, reliability, and regulatory workspaces.",
          "mobile" => "Search common questions and open complete answers from a narrow screen."
        }.fetch(state)
      end
    end
  end
end
