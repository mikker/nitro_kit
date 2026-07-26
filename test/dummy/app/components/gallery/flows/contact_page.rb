module Gallery
  module Flows
    class ContactPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      private

      def render_scenario
        workspace_surface(size: :lg) do
          render_header

          if state == "sent"
            render_sent
          else
            render_contact_form
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: contact_title,
          description: state_description,
          id: "gallery-contact-header"
        ) do |header|
          header.actions(NitroKit::ButtonGroup.new(id: "gallery-contact-actions", label: "Contact page actions")) do |actions|
            actions.button("View pricing", href: pricing_path)
            actions.button("Email sales", href: "mailto:sales@example.test", variant: :primary)
          end
        end
      end

      def render_contact_form
        inquiry = contact_inquiry
        disabled = state.in?(%w[sending unavailable])

        render NitroKit::FormSection.new(
          title: "Tell us about your application",
          description: "Routing, response times, persistence, consent, and delivery remain application responsibilities.",
          id: "gallery-contact-form-section"
        ) do |section|
          render_form_status(section, inquiry)
          section.form do
            form_with(
              model: inquiry,
              scope: :contact,
              url: "#contact-inquiries",
              builder: NitroKit::FormBuilder,
              id: "gallery-contact-form"
            ) do |form|
              form.fieldset(
                legend: "Contact details",
                description: "Do not include passwords, API credentials, payment card details, or regulated personal data.",
                disabled:,
                html: { id: "gallery-contact-fieldset" }
              ) do
                form.group do
                  form.field(:name, autocomplete: "name", required: true, disabled:)
                  form.field(:email, as: :email, autocomplete: "email", required: true, disabled:)
                  form.field(:company, autocomplete: "organization", disabled:)
                  form.field(
                    :topic,
                    as: :select,
                    options: Gallery::Forms::ContactInquiry::TOPICS.map { |topic| [ topic.humanize, topic ] },
                    prompt: "Choose a topic",
                    required: true,
                    disabled:
                  )
                  form.field(
                    :message,
                    as: :textarea,
                    label: "How can we help?",
                    required: true,
                    disabled:,
                    minlength: 20,
                    maxlength: 2_000
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-contact-toolbar") do |toolbar|
                toolbar.leading do
                  render NitroKit::Button.new("Privacy policy", href: "#privacy")
                end
                toolbar.trailing do
                  form.submit(
                    state == "sending" ? "Sending inquiry…" : "Send inquiry",
                    id: "gallery-contact-submit",
                    disabled:,
                    data: { turbo_submits_with: "Sending inquiry…" }
                  )
                end
              end
            end
          end
        end
      end

      def render_form_status(section, inquiry)
        case state
        when "validation"
          section.status(NitroKit::Alert.new(variant: :error, id: "gallery-contact-validation")) do |alert|
            alert.title("Your inquiry needs attention")
            alert.description(inquiry.errors.full_messages.to_sentence)
          end
        when "sending"
          section.status(NitroKit::Alert.new(id: "gallery-contact-sending")) do |alert|
            alert.title("Sending your inquiry")
            alert.description("Keep this page open while the application creates the conversation.")
          end
        when "unavailable"
          section.status(NitroKit::Alert.new(variant: :warning, id: "gallery-contact-unavailable")) do |alert|
            alert.title("The contact form is temporarily unavailable")
            alert.description("No inquiry was created. Email sales@example.test or try again later.")
          end
        end
      end

      def render_sent
        render NitroKit::Alert.new(variant: :success, id: "gallery-contact-sent") do |alert|
          alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-contact-sent-icon"))
          alert.title("Inquiry CON-2048 was sent")
          alert.description("The sales team will reply to ada@example.test within one business day.")
        end

        render NitroKit::DataSection.new(
          title: "Inquiry summary",
          description: "The application exposes the durable result instead of replacing it with a transient notification.",
          id: "gallery-contact-sent-summary"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Contact result actions")) do |actions|
            actions.button("Send another inquiry", href: entry_path(entry, state: "form"))
          end
          section.table(NitroKit::Table.new(id: "gallery-contact-sent-table")) do |table|
            table.caption("Submitted contact inquiry")
            table.thead do
              table.tr do
                table.th("Detail")
                table.th("Value")
              end
            end
            table.tbody do
              [
                [ "Reference", "CON-2048" ],
                [ "Topic", "Enterprise" ],
                [ "Reply email", "ada@example.test" ],
                [ "Submitted", "July 13, 2026 at 11:18 UTC" ]
              ].each do |label, value|
                table.tr do
                  table.th(label, scope: :row)
                  table.td(value)
                end
              end
            end
          end
        end
      end

      def contact_inquiry
        attributes = case state
        when "validation"
          { name: "", email: "invalid", company: "Analytical Engines", topic: "unknown", message: "Too short" }
        when "long"
          {
            name: "Rear Admiral Grace Brewster Murray Hopper",
            email: "grace.hopper+international-research-and-production@example.test",
            company: "Analytical Engines — International Research, Production, Reliability Engineering, and Customer Operations",
            topic: "enterprise",
            message: "We need procurement, security review, data residency, invoicing, and priority support for regulated production teams across four regions."
          }
        else
          {
            name: "Ada Lovelace",
            email: "ada@example.test",
            company: "Analytical Engines",
            topic: "sales",
            message: "We are evaluating Nitro Kit for a production Rails application used by several engineering teams."
          }
        end

        Gallery::Forms::ContactInquiry.new(attributes).tap do |inquiry|
          inquiry.validate if state == "validation"
        end
      end

      def contact_title
        return "Talk with us about International Research, Production, Reliability Engineering, and Customer Operations" if state == "long"
        return "Thanks for getting in touch" if state == "sent"

        "Talk with the Nitro Kit team"
      end

      def pricing_path
        gallery_flow_path(slug: "pricing", state: "monthly")
      end

      def loading_state?
        state == "sending"
      end

      def flow_label = "Public contact flow"
      def section_title = "Contact and inquiry delivery"
      def section_description = "Form, validation, submission, result, availability, long-content, and narrow states."

      def state_description
        {
          "form" => "A real Active Model inquiry preserves Rails values, labels, names, constraints, and topic choices.",
          "validation" => "Server validation keeps invalid caller values connected to accessible field errors.",
          "sending" => "Every mutable control is disabled while the caller-owned route creates the inquiry.",
          "sent" => "A durable result exposes reference, topic, reply address, and response expectation.",
          "unavailable" => "A delivery outage disables mutation and presents an independent contact route.",
          "long" => "Long names, addresses, organization identity, and inquiry copy wrap without custom styling.",
          "mobile" => "The accepted field and toolbar layout own narrow stacking without a mobile API."
        }.fetch(state)
      end
    end
  end
end
