module Gallery
  module Compositions
    class CheckoutPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      private

      def render_scenario
        workspace_surface do
          render_header

          case state
          when "review" then render_review
          when "payment", "validation", "processing" then render_payment
          when "succeeded" then render_result(:success, "Payment complete", "Team plan access is active and receipt CHK-2048 was emailed.")
          when "failed" then render_failed
          when "requires-action" then render_requires_action
          when "cancelled" then render_result(:warning, "Checkout cancelled", "No charge was created and the current Starter plan remains active.")
          when "refunded" then render_result(:success, "Payment refunded", "$49.00 was returned to Visa ending in 4242. Bank settlement can take five business days.")
          when "empty-cart" then render_empty_cart
          when "long" then render_long
          when "mobile" then render_mobile
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: checkout_title,
          eyebrow: "Secure checkout",
          description: checkout_description,
          id: "gallery-checkout-header"
        ) do |header|
          header.actions NitroKit::ButtonGroup.new(label: "Checkout navigation", id: "gallery-checkout-navigation") do |actions|
            actions.button("Back to plans", href: "#plans", disabled: state == "processing")
          end
        end
      end

      def render_review
        render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-checkout-review-grid") do
          render_summary_card("Team plan", "$49.00 monthly", "20 members · unlimited projects · email support")
          render_summary_card("Billing contact", "Ada Lovelace", "accounts-payable@example.test")
          render_summary_card("Due today", "$49.00", "Renews August 13, 2026 unless cancelled")
        end

        render NitroKit::Toolbar.new(id: "gallery-checkout-review-actions") do |toolbar|
          toolbar.leading { render NitroKit::Badge.new("No charge yet", color: :info) }
          toolbar.trailing do
            render NitroKit::Button.new(
              "Continue to payment",
              href: entry_path(entry, state: "payment"),
              id: "gallery-checkout-continue",
              variant: :primary
            )
          end
        end
      end

      def render_summary_card(title, value, detail)
        render NitroKit::Card.new do |card|
          card.title(title)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              strong { value }
              p { detail }
            end
          end
        end
      end

      def render_payment
        invalid = state == "validation"
        disabled = state == "processing"
        payment = payment_example(invalid:)

        render NitroKit::FormSection.new(
          title: "Payment method",
          description: "Card collection, tokenization, submission routes, and payment policy remain application code.",
          id: "gallery-checkout-payment-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, id: "gallery-checkout-payment-error") do |alert|
              alert.title("Payment details need attention")
              alert.description("Correct every highlighted field before asking the payment provider to authorize the charge.")
            end
          elsif disabled
            section.status NitroKit::Alert.new(id: "gallery-checkout-processing") do |alert|
              alert.title("Authorizing payment")
              alert.description("Keep this page open while the provider confirms the card and billing address.")
            end
          end

          section.form do
            form_with(
              model: payment,
              url: "#checkout-payment",
              builder: NitroKit::FormBuilder,
              id: "gallery-checkout-payment-form"
            ) do |form|
              form.group do
                form.field(:cardholder_name, label: "Cardholder name", autocomplete: "cc-name", required: true, disabled:)
                form.field(
                  :card_number,
                  label: "Card number",
                  autocomplete: "cc-number",
                  inputmode: "numeric",
                  required: true,
                  disabled:
                )
                form.field(:expiry, label: "Expiry", autocomplete: "cc-exp", required: true, disabled:)
                form.field(:billing_email, as: :email, label: "Receipt email", autocomplete: "email", required: true, disabled:)
                form.field(:postal_code, label: "Billing postal code", autocomplete: "postal-code", required: true, disabled:)
                form.submit(
                  disabled ? "Authorizing payment…" : "Pay $49.00",
                  id: "gallery-checkout-payment-submit",
                  disabled:,
                  data: { turbo_submits_with: "Authorizing payment…" }
                )
              end
            end
          end
        end
      end

      def render_result(variant, title, description)
        render NitroKit::Card.new(id: "gallery-checkout-result") do |card|
          card.title(title)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Alert.new(variant:, id: "gallery-checkout-result-alert") do |alert|
                alert.icon NitroKit::Icon.new(variant == :warning ? :triangle_alert : :circle_check)
                alert.title(title)
                alert.description(description)
              end
              dl(data: { gallery: "checkout-result-metadata" }) do
                dt { "Reference" }
                dd { state == "refunded" ? "RFN-2048" : "CHK-2048" }
                dt { "Recorded" }
                dd { "July 13, 2026 at 10:42 UTC" }
              end
            end
          end
          card.footer do
            render NitroKit::Button.new(
              state == "succeeded" ? "Open workspace" : "Return to billing",
              href: "#billing",
              variant: :primary,
              id: "gallery-checkout-result-action"
            )
          end
        end
      end

      def render_failed
        render NitroKit::FormSection.new(
          title: "Try payment again",
          description: "The previous authorization was declined. No workspace access or subscription state changed.",
          id: "gallery-checkout-failed-section"
        ) do |section|
          section.status NitroKit::Alert.new(variant: :error, id: "gallery-checkout-failed-alert") do |alert|
            alert.title("Card was declined")
            alert.description("Ask the card issuer for details or submit a different payment method.")
          end
          section.form do
            form_with(url: "#checkout-retry", scope: :retry, builder: NitroKit::FormBuilder, id: "gallery-checkout-retry-form") do |form|
              form.group do
                form.field(:card_number, label: "Replacement card number", autocomplete: "cc-number", required: true)
                form.field(:postal_code, label: "Billing postal code", autocomplete: "postal-code", required: true)
                form.submit("Retry $49.00 payment", id: "gallery-checkout-retry-submit")
              end
            end
          end
        end
      end

      def render_requires_action
        render NitroKit::Card.new(id: "gallery-checkout-action-card") do |card|
          card.title("Bank confirmation required")
          card.body do
            render NitroKit::Alert.new(variant: :warning, id: "gallery-checkout-action-alert") do |alert|
              alert.title("Complete 3-D Secure verification")
              alert.description("The bank opened an additional verification step. Nitro owns only this visible state, not the provider challenge.")
            end
          end
          card.footer do
            render NitroKit::Button.new("Continue bank verification", href: "#provider-challenge", variant: :primary, id: "gallery-checkout-provider-action")
          end
        end
      end

      def render_empty_cart
        render NitroKit::EmptyState.new(
          title: "No plan selected",
          description: "Choose a plan before entering payment details.",
          id: "gallery-checkout-empty"
        ) do |empty|
          empty.icon NitroKit::Icon.new(:shopping_cart)
          empty.action NitroKit::Button.new("Compare plans", href: "#plans", variant: :primary, id: "gallery-checkout-empty-action")
        end
      end

      def render_long
        render NitroKit::Card.new(id: "gallery-checkout-long-card") do |card|
          card.title("International Research, Production, Reliability, and Regulatory Archive Team plan")
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              p do
                "The first charge covers 118 active members, 27 connected production environments, replicated audit storage, " \
                  "priority incident response, and tax documentation for accounts-payable+international-research-and-production@example.test."
              end
              render NitroKit::Badge.new("Due today: DKK 18,492.75", color: :warning)
            end
          end
          card.footer do
            render NitroKit::Button.new("Review complete order and tax details", href: entry_path(entry, state: "review"), variant: :primary)
          end
        end
      end

      def render_mobile
        render NitroKit::Card.new(id: "gallery-checkout-mobile-card") do |card|
          card.title("Team plan checkout")
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              p { "$49.00 due today" }
              p { "Visa ending in 4242 · receipt to accounts-payable@example.test" }
            end
          end
          card.footer do
            render NitroKit::Button.new("Pay securely", href: entry_path(entry, state: "payment"), variant: :primary, id: "gallery-checkout-mobile-action")
          end
        end
      end

      def payment_example(invalid:)
        attributes = invalid ?
          { cardholder_name: "", card_number: "4242", expiry: "7/26", billing_email: "invalid", postal_code: "" } :
          { cardholder_name: "Ada Lovelace", card_number: "4242424242424242", expiry: "08/28", billing_email: "billing@example.test", postal_code: "SW1A 1AA" }

        Gallery::Forms::PaymentMethod.new(**attributes).tap { |payment| payment.validate if invalid }
      end

      def checkout_title
        {
          "review" => "Review order",
          "payment" => "Enter payment details",
          "validation" => "Correct payment details",
          "processing" => "Authorizing payment",
          "succeeded" => "Checkout complete",
          "failed" => "Payment failed",
          "requires-action" => "Confirm payment with your bank",
          "cancelled" => "Checkout cancelled",
          "refunded" => "Payment refunded",
          "empty-cart" => "Choose a plan",
          "long" => "Review enterprise checkout",
          "mobile" => "Checkout"
        }.fetch(state)
      end

      def checkout_description
        {
          "review" => "Confirm plan, contact, renewal, and amount before payment.",
          "payment" => "Submit one complete application-owned payment form.",
          "validation" => "Provider-safe validation remains connected to native fields.",
          "processing" => "The visible surface stays stable while every mutation is disabled.",
          "succeeded" => "Access, receipt, amount, and reference are explicit.",
          "failed" => "Failure leaves subscription state unchanged and offers a safe retry.",
          "requires-action" => "An external bank challenge is represented without embedding provider policy.",
          "cancelled" => "Cancellation confirms that no charge or subscription change occurred.",
          "refunded" => "Refund amount, destination, reference, and settlement expectation are visible.",
          "empty-cart" => "Checkout cannot begin until the application supplies a selected plan.",
          "long" => "Long plan, tax, member, environment, and recipient content remains readable.",
          "mobile" => "The same checkout decisions collapse on a narrow surface."
        }.fetch(state)
      end

      def composition_label = "Checkout and payment"
      def section_title = "Checkout and payment outcomes"
      def section_description = "Order review, card entry, provider outcomes, cancellation, refunds, content pressure, and narrow layouts."
      def state_description = checkout_description
    end
  end
end
