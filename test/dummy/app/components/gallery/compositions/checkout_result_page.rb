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
          title: "Order #{outcome.reference}",
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
          description: "Review the amount and the next step for this order.",
          id: "gallery-checkout-result-page-summary"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Order summary actions")) do |actions|
            actions.button("Download record", href: "#download-#{outcome.reference.downcase}")
          end
          section.table NitroKit::DetailsTable.new(
            outcome,
            caption: "Checkout outcome details",
            id: "gallery-checkout-result-page-table"
          ) do |details|
            details.fields(:reference, :amount, :next_step)
            details.field(:recorded, value: "July 13, 2026 at 11:24 UTC")
          end
        end
      end

      def outcome
        @outcome ||= Gallery::PublicData.checkout_outcome(state)
      end

      def section_title = "Asynchronous and non-card checkout outcomes"
      def section_description = "Invoice, transfer, trial, account credit, manual review, and pressure states not duplicated by checkout."

      def state_description
        {
          "invoice-issued" => "Your net-30 invoice is ready. Access starts after payment is received.",
          "bank-transfer-pending" => "The order is recorded and access starts after the transfer settles.",
          "trial-started" => "Team features are active for 14 days and no payment method was charged.",
          "credit-applied" => "Workspace credit covered the renewal without charging the saved card.",
          "manual-review" => "The order is saved while billing operations verify tax and organization details.",
          "long" => "The enterprise invoice is ready for procurement review and multi-region tax processing.",
          "mobile" => "The transfer is pending. Use the order reference when sending payment."
        }.fetch(state)
      end
    end
  end
end
