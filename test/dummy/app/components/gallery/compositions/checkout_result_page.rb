module Gallery
  module Compositions
    class CheckoutResultPage < ScenarioPage
      private

      def render_scenario
        workspace_surface(size: :lg) do
          render_header
          render_outcome
          render_summary
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: "Checkout result",
          description: state_description,
          id: "gallery-checkout-result-page-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(id: "gallery-checkout-result-page-actions", label: "Checkout result actions")
          ) do |actions|
            actions.button("Return to billing", href: "#billing")
            actions.button(outcome.action, href: outcome.href, variant: :primary)
          end
        end
      end

      def render_outcome
        render NitroKit::Alert.new(
          variant: outcome.variant,
          id: "gallery-checkout-result-page-alert",
          data: { gallery_checkout_outcome: outcome.state }
        ) do |alert|
          alert.icon(NitroKit::Icon.new(outcome.icon, id: "gallery-checkout-result-page-icon"))
          alert.title(outcome.title)
          alert.description(outcome.description)
        end
      end

      def render_summary
        render NitroKit::DataSection.new(
          title: "Order summary",
          description: "The application owns payment state, entitlement timing, references, amounts, and next steps.",
          id: "gallery-checkout-result-page-summary"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Order summary actions")) do |actions|
            actions.button("Download record", href: "#download-#{outcome.reference.downcase}")
          end
          section.table(NitroKit::Table.new(id: "gallery-checkout-result-page-table")) do |table|
            table.caption("Caller-owned checkout outcome details")
            table.thead do
              table.tr do
                table.th("Detail")
                table.th("Value")
              end
            end
            table.tbody do
              [
                [ "Reference", outcome.reference ],
                [ "Amount", outcome.amount ],
                [ "Next step", outcome.next_step ],
                [ "Recorded", "July 13, 2026 at 11:24 UTC" ]
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

      def outcome
        @outcome ||= Gallery::PublicData.checkout_outcome(state)
      end

      def composition_label = "Checkout result"
      def section_title = "Asynchronous and non-card checkout outcomes"
      def section_description = "Invoice, transfer, trial, account credit, manual review, and pressure states not duplicated by checkout."

      def state_description
        {
          "invoice-issued" => "An approved net-terms order exposes invoice identity, due date, and activation timing.",
          "bank-transfer-pending" => "An asynchronous transfer separates recorded order state from settled access.",
          "trial-started" => "A zero-charge trial result identifies the end date without claiming a payment.",
          "credit-applied" => "Account credit identifies the covered amount, card charge, and remaining balance.",
          "manual-review" => "Manual tax and organization review keeps authorization distinct from captured payment.",
          "long" => "Long procurement identity, amount, reference, and next-step copy wrap without truncation.",
          "mobile" => "A concise transfer outcome retains complete reference and settlement semantics on a narrow surface."
        }.fetch(state)
      end
    end
  end
end
