module Gallery
  module Compositions
    class CheckoutPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      CheckoutResult = ::Data.define(:reference, :recorded)

      private

      def render_scenario
        workspace_surface do
          render_header

          case state
          when "review" then render_review
          when "payment", "validation", "processing" then render_payment
          when "succeeded" then render_result(:success, "Team plan activated", "Team plan access is active and receipt CHK-2048 was emailed.")
          when "failed" then render_failed
          when "requires-action" then render_requires_action
          when "cancelled" then render_result(:warning, "No charge created", "No charge was created and the current Starter plan remains active.")
          when "refunded" then render_result(:success, "Refund sent", "$49.00 was returned to Visa ending in 4242. Bank settlement can take five business days.")
          when "empty-cart" then render_empty_cart
          when "long" then render_long
          when "mobile" then render_mobile
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: checkout_title,
          description: checkout_description,
          id: "gallery-checkout-header"
        ) do |header|
          header.actions NitroKit::ButtonGroup.new(label: "Checkout navigation", id: "gallery-checkout-navigation") do |actions|
            actions.button("Back to plans", href: "#plans", icon: :arrow_left, disabled: state == "processing")
          end
        end
      end

      def render_review
        render NitroKit::StatGrid.new(id: "gallery-checkout-review-grid") do |stats|
          stats.stat(key: :plan, label: "Plan", value: "Team", detail: "20 members · unlimited projects · email support")
          stats.stat(key: :contact, label: "Billing contact", value: "Ada Lovelace", detail: "Receipt to accounts-payable@example.test")
          stats.stat(key: :total, label: "Due today", value: "$49.00", detail: "Renews August 13, 2026 unless cancelled")
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

      def render_payment
        invalid = state == "validation"
        disabled = state == "processing"
        payment = payment_example(invalid:)

        render NitroKit::SettingsSection.new(
          title: "Payment method",
          description: "Your card is charged only after you submit this form. We will email the receipt to the billing address below.",
          id: "gallery-checkout-payment-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, live: :assertive, id: "gallery-checkout-payment-error") do |alert|
              alert.title("Payment details need attention")
              alert.description("Correct the highlighted fields before trying the payment again.")
            end
          elsif disabled
            section.status NitroKit::Alert.new(variant: :info, live: :polite, id: "gallery-checkout-processing") do |alert|
              alert.title("Authorizing payment")
              alert.description("Keep this page open while we confirm the card and billing address.")
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
        render NitroKit::Flex.new(dir: :col, gap: 5, align: :stretch, id: "gallery-checkout-result") do
          render NitroKit::Alert.new(variant:, id: "gallery-checkout-result-alert") do |alert|
            alert.icon NitroKit::Icon.new(variant == :warning ? :triangle_alert : :circle_check)
            alert.title(title)
            alert.description(description)
          end
          render NitroKit::DetailsTable.new(
            checkout_result,
            caption: "Checkout record",
            data: { gallery: "checkout-result-metadata" }
          ) do |details|
            details.fields(:reference, :recorded)
          end
          render NitroKit::Toolbar.new(id: "gallery-checkout-result-actions") do |toolbar|
            toolbar.trailing do
              render NitroKit::Button.new(
                state == "succeeded" ? "Open workspace" : "Return to billing",
                href: "#billing",
                variant: :primary,
                id: "gallery-checkout-result-action"
              )
            end
          end
        end
      end

      def render_failed
        render NitroKit::SettingsSection.new(
          title: "Try payment again",
          description: "Use another card or confirm the billing details with your card issuer.",
          id: "gallery-checkout-failed-section"
        ) do |section|
          section.status NitroKit::Alert.new(variant: :error, live: :assertive, id: "gallery-checkout-failed-alert") do |alert|
            alert.title("Card was declined")
            alert.description("No charge was made and your current plan is unchanged.")
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
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-checkout-action-card") do
          render NitroKit::Alert.new(variant: :warning, id: "gallery-checkout-action-alert") do |alert|
            alert.icon NitroKit::Icon.new(:shield_check)
            alert.title("Complete 3-D Secure verification")
            alert.description("Your bank needs one more confirmation before we can finish the payment.")
          end
          render NitroKit::Toolbar.new do |toolbar|
            toolbar.trailing do
              render NitroKit::Button.new("Continue bank verification", href: "#provider-challenge", variant: :primary, icon_end: :arrow_right, id: "gallery-checkout-provider-action")
            end
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

      def checkout_result
        CheckoutResult.new(
          reference: state == "refunded" ? "RFN-2048" : "CHK-2048",
          recorded: "July 13, 2026 at 10:42 UTC"
        )
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
          "review" => "Confirm your plan, billing contact, renewal date, and total before continuing.",
          "payment" => "Pay $49.00 today to activate the Team plan for your workspace.",
          "validation" => "A few payment details need to be corrected before we can continue.",
          "processing" => "We are confirming your payment. This usually takes only a few seconds.",
          "succeeded" => "Your Team plan is active and the receipt is on its way.",
          "failed" => "The card was not charged. You can safely try another payment method.",
          "requires-action" => "Finish the security check with your bank to complete this payment.",
          "cancelled" => "Your checkout was cancelled before a charge was created.",
          "refunded" => "The refund has been sent to the original payment method.",
          "empty-cart" => "Select a plan before entering payment details.",
          "long" => "Confirm the full plan, member, tax, and billing details before payment.",
          "mobile" => "Review the amount and payment destination before continuing."
        }.fetch(state)
      end

      def section_title = "Checkout and payment outcomes"
      def section_description = "Order review, card entry, provider outcomes, cancellation, refunds, content pressure, and narrow layouts."
    end
  end
end
