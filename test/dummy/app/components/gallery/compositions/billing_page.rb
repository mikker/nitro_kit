module Gallery
  module Compositions
    class BillingPage < Page
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      BillingOverview = ::Data.define(:next_invoice, :receipt_destination, :payment_method)

      CANCELLATION_REASONS = [
        [ "The plan is too expensive", "too_expensive" ],
        [ "A feature we need is missing", "missing_feature" ],
        [ "We only need a temporary pause", "temporary_pause" ],
        [ "We are switching to another service", "switching_service" ],
        [ "Another reason", "other" ]
      ].freeze

      private

      def page_template
        render_composition_header

        render Section.new(
          slug: "billing-screen",
          title: "Subscription billing",
          description: "Plans, card replacement, paginated invoice records, cancellation safeguards, outcomes, and pressure states."
        ) do
          render_example(
            slug: "billing-#{state}",
            title: humanize_state(state),
            description: state_description,
            mode: :full_width
          ) do
            div(
              data: {
                gallery: "composition-surface",
                gallery_composition: "billing",
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-billing-container") do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-billing-stack") do
                  turbo_frame_tag("gallery-billing-frame") { render_screen }
                end
              end
            end
          end
        end
      end

      def render_screen
        case state
        when "plans"
          render_plans
        when "payment-method", "payment-validation", "payment-loading"
          render_payment_method
        when "payment-updated"
          render_payment_updated
        when "invoices"
          render_invoice_history
        when "invoice-detail"
          render_invoice_detail
        when "invoice-empty"
          render_invoice_empty
        when "cancellation", "cancellation-validation", "cancellation-loading"
          render_cancellation
        when "cancelled"
          render_cancelled
        when "mobile"
          render_mobile_overview
        end
      end

      def render_plans
        render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-billing-plans-stack") do
          render NitroKit::Card.new(id: "gallery-billing-plan-summary") do |card|
            card.title("Team plan", level: 4)
            card.body do
              render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
                render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
                  render NitroKit::Badge.new("Current plan", id: "gallery-billing-current-plan", color: :success, size: :sm)
                end
                p { "$49.00 per month · 18 active members · renews August 1, 2026" }
                p { "Plans are billed monthly in US dollars and can be changed at any time." }
              end
            end
            card.divider
            card.footer do
              render NitroKit::Button.new(
                "Review invoices",
                id: "gallery-billing-plan-invoices",
                href: entry_path(entry, state: "invoices")
              )
            end
          end

          render NitroKit::Grid.new(
            cols: "1 sm:2 lg:3",
            id: "gallery-billing-plan-grid",
            aria: { label: "Available plans" },
            data: { gallery: "billing-plan-grid" }
          ) do
            Gallery::Data.plans.each do |plan|
              render NitroKit::Card.new(id: "gallery-billing-#{plan.id}") do |card|
                card.title(plan.name, level: 5)
                card.body do
                  render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
                    render NitroKit::Typeset.new do
                      p { plan_price(plan) }
                      ul do
                        plan.features.each { |feature| li { feature } }
                      end
                    end
                    if plan.current
                      render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
                        render NitroKit::Badge.new("Current plan", id: "gallery-billing-#{plan.id}-badge", color: :success)
                      end
                    end
                  end
                end
                card.divider
                card.footer do
                  render NitroKit::Button.new(
                    plan.current ? "Manage Team plan" : "Choose #{plan.name}",
                    id: "gallery-billing-#{plan.id}-choose",
                    href: plan.current ? entry_path(entry, state: "cancellation") : "#choose-#{plan.id}",
                    variant: plan.current ? :default : :primary,
                    disabled: plan.current
                  )
                end
              end
            end
          end
        end
      end

      def render_payment_method
        invalid = state == "payment-validation"
        disabled = state == "payment-loading"
        payment_method = payment_method_example(invalid:)

        render NitroKit::SettingsSection.new(
          title: "Replace payment method",
          description: "Update the card and receipt destination used for future Team plan charges.",
          id: "gallery-billing-payment-card"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(id: "gallery-billing-payment-validation", variant: :destructive) do |alert|
              alert.title("Payment method was not saved")
              alert.description(payment_method.errors.full_messages.to_sentence)
            end
          end

          section.form do
            render NitroKit::Alert.new(id: "gallery-billing-current-payment") do |alert|
              alert.title("Current card")
              alert.description("Visa ending in 4242 · expires 08/26 · next charge August 1, 2026")
            end

            form_with(
              model: payment_method,
              url: "#payment-method",
              builder: NitroKit::FormBuilder,
              id: "gallery-billing-payment-form",
              data: { turbo_frame: "gallery-billing-frame" }
            ) do |form|
              form.group do
                form.field(
                  :cardholder_name,
                  label: "Name on card",
                  autocomplete: "cc-name",
                  required: true,
                  disabled:
                )
                form.field(
                  :card_number,
                  label: "Card number",
                  description: "Enter 16 digits without spaces.",
                  autocomplete: "cc-number",
                  inputmode: "numeric",
                  pattern: "[0-9]{16}",
                  required: true,
                  disabled:
                )
                form.field(
                  :expiry,
                  label: "Expiry",
                  description: "Use MM/YY.",
                  autocomplete: "cc-exp",
                  inputmode: "numeric",
                  pattern: "(?:0[1-9]|1[0-2])/[0-9]{2}",
                  required: true,
                  disabled:
                )
                form.field(
                  :billing_email,
                  as: :email,
                  label: "Receipt email",
                  autocomplete: "email",
                  required: true,
                  disabled:
                )
                form.field(
                  :postal_code,
                  label: "Billing postal code",
                  autocomplete: "postal-code",
                  required: true,
                  disabled:
                )
                render NitroKit::Toolbar.new(id: "gallery-billing-payment-actions") do |toolbar|
                  toolbar.leading do
                    render NitroKit::Button.new(
                      "Back to plans",
                      id: "gallery-billing-payment-back",
                      href: entry_path(entry, state: "plans")
                    )
                  end
                  toolbar.trailing do
                    form.submit(
                      disabled ? "Saving payment method…" : "Save payment method",
                      id: "gallery-billing-payment-submit",
                      disabled:,
                      data: { turbo_submits_with: "Saving payment method…" }
                    )
                  end
                end
              end
            end
          end
        end
      end

      def render_payment_updated
        render NitroKit::Card.new(id: "gallery-billing-payment-updated-card") do |card|
          card.title("Payment method updated", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Alert.new(id: "gallery-billing-payment-updated", variant: :success) do |alert|
                alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-billing-payment-updated-icon"))
                alert.title("Visa ending in 4242 is ready")
                alert.description("Future Team plan charges and retry attempts will use this card.")
              end
              render NitroKit::DetailsTable.new(
                payment_method_example(invalid: false),
                data: { gallery: "billing-payment-summary" }
              ) do |details|
                details.field(:cardholder_name, label: "Cardholder")
                details.field(:billing_email, label: "Receipt email")
                details.field(:next_charge, value: "$49.00 on August 1, 2026")
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new(
              "View invoice history",
              id: "gallery-billing-payment-updated-continue",
              href: entry_path(entry, state: "invoices"),
              variant: :primary
            )
          end
        end
      end

      def render_invoice_history
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch, id: "gallery-billing-invoices-stack") do
          render NitroKit::DataSection.new(
            title: "Invoice history",
            description: "Paid and refunded records remain available to workspace owners for accounting and audit purposes.",
            id: "gallery-billing-invoices-card"
          ) do |section|
            section.actions NitroKit::ButtonGroup.new(
              id: "gallery-billing-invoice-history-actions",
              label: "Invoice history actions"
            ) do |group|
              group.button(
                "View latest invoice",
                id: "gallery-billing-latest-invoice",
                href: entry_path(entry, state: "invoice-detail"),
                variant: :primary
              )
            end
            section.table NitroKit::Table.new(
              id: "gallery-billing-invoice-table",
              table_aria: { label: "Invoices for Analytical Engines — Research and Production" }
            ) do |table|
              render_invoice_table(table)
            end
          end
          render_invoice_pagination
        end
      end

      def render_invoice_table(table)
        table.caption("Invoices for Analytical Engines — Research and Production")
        table.thead do
          table.tr do
            table.th("Invoice")
            table.th("Issued")
            table.th("Due")
            table.th("Status")
            table.th("Amount", align: :right)
          end
        end
        table.tbody do
          Gallery::Data.invoices.each do |invoice|
            table.tr do
              table.th(invoice.number, scope: :row)
              table.td(invoice.issued_on.to_fs(:long))
              table.td(invoice.due_on.to_fs(:long))
              table.td do
                render NitroKit::Badge.new(
                  invoice.status.to_s.humanize,
                  id: "gallery-billing-#{invoice.id}-status",
                  color: invoice_status_color(invoice.status),
                  size: :sm
                )
              end
              table.td(format_amount(invoice.amount_cents, invoice.currency), align: :right)
            end
          end
        end
      end

      def render_invoice_pagination
        render NitroKit::PaginationBar.new(id: "gallery-billing-invoice-pagination-bar") do |bar|
          bar.summary(
            "Showing the three most recent of 36 invoices",
            html: { id: "gallery-billing-invoice-summary" }
          )
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-billing-invoice-pagination",
              label: "Invoice history pages"
            )
          ) do |pagination|
            pagination.prev(
              href: invoice_page_path(11),
              id: "gallery-billing-invoice-pagination-previous"
            )
            pagination.page(
              1,
              href: invoice_page_path(1),
              id: "gallery-billing-invoice-pagination-page-1"
            )
            pagination.ellipsis(label: "Pages 2 through 9 omitted")
            pagination.page(
              10,
              href: invoice_page_path(10),
              id: "gallery-billing-invoice-pagination-page-10"
            )
            pagination.page(
              11,
              href: invoice_page_path(11),
              id: "gallery-billing-invoice-pagination-page-11"
            )
            pagination.page(12, current: true, id: "gallery-billing-invoice-pagination-page-12")
            pagination.next(id: "gallery-billing-invoice-pagination-next")
          end
        end
      end

      def invoice_page_path(page)
        gallery_composition_path(slug: entry.slug, state: "invoices", page:)
      end

      def render_invoice_detail
        invoice = Gallery::Data.invoices.first

        render NitroKit::Card.new(id: "gallery-billing-invoice-detail-card") do |card|
          card.title("Invoice #{invoice.number}", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
                render NitroKit::Badge.new("Paid", id: "gallery-billing-invoice-detail-status", color: :success)
              end
              render NitroKit::DetailsTable.new(
                invoice,
                data: { gallery: "billing-invoice-metadata" }
              ) do |details|
                details.field(:issued_on, label: "Issued") { |date| plain date.to_fs(:long) }
                details.field(:paid, value: "July 1, 2026 at 08:04 UTC")
                details.field(:billed_to, value: "Analytical Engines Ltd., 12 Long Calculation Street, London SW1A 1AA, United Kingdom")
                details.field(:payment_method, value: "Visa ending in 4242")
              end

              render NitroKit::Table.new(id: "gallery-billing-invoice-lines") do |table|
                table.caption("Line items for #{invoice.number}")
                table.thead do
                  table.tr do
                    table.th("Description")
                    table.th("Period")
                    table.th("Amount", align: :right)
                  end
                end
                table.tbody do
                  table.tr do
                    table.th("Team plan — 20 member workspace", scope: :row)
                    table.td("July 1–31, 2026")
                    table.td("$49.00", align: :right)
                  end
                  table.tr do
                    table.th("Value-added tax", scope: :row)
                    table.td("Reverse charge")
                    table.td("$0.00", align: :right)
                  end
                  table.tr do
                    table.th("Total paid", scope: :row)
                    table.td("USD")
                    table.td("$49.00", align: :right)
                  end
                end
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::ButtonGroup.new(id: "gallery-billing-invoice-actions", label: "Invoice actions") do |group|
              group.button(
                "Download PDF",
                id: "gallery-billing-invoice-download",
                href: "/gallery/invoices/#{invoice.id}.pdf",
                download: "#{invoice.number}.pdf",
                variant: :primary
              )
              group.button(
                "Back to history",
                id: "gallery-billing-invoice-back",
                href: entry_path(entry, state: "invoices")
              )
            end
          end
        end
      end

      def render_invoice_empty
        render NitroKit::DataSection.new(
          title: "Invoice history",
          description: "Receipts and tax documents appear here after the workspace has a paid charge.",
          id: "gallery-billing-invoice-empty-card"
        ) do |section|
          section.empty_state NitroKit::EmptyState.new(
            title: "No invoices yet",
            description: "Starter is free, so there are no receipts or tax documents to download.",
            level: 3,
            id: "gallery-billing-invoice-empty"
          ) do |empty_state|
            empty_state.action NitroKit::Button.new(
              "Compare paid plans",
              id: "gallery-billing-invoice-empty-plans",
              href: entry_path(entry, state: "plans"),
              variant: :primary
            )
          end
        end
      end

      def render_cancellation
        invalid = state == "cancellation-validation"
        disabled = state == "cancellation-loading"
        cancellation = cancellation_example(invalid:)

        render NitroKit::DangerZone.new(
          title: "Cancel Team plan",
          description: "Paid access ends August 1, 2026. Eighteen active members and paid workspace history will be affected.",
          id: "gallery-billing-cancellation-card"
        ) do |zone|
          zone.confirmation do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch,
            id: "gallery-billing-cancellation-confirmation") do
              if invalid
                render NitroKit::Alert.new(id: "gallery-billing-cancellation-validation", variant: :destructive) do |alert|
                  alert.title("Confirm the cancellation details")
                  alert.description(cancellation.errors.full_messages.to_sentence)
                end
              else
                render NitroKit::Alert.new(id: "gallery-billing-cancellation-warning", variant: :warning) do |alert|
                  alert.title("Paid access ends August 1, 2026")
                  alert.description(
                    "Exports remain available, but 18 active members, audit history, and seats beyond the Starter " \
                      "limit become read-only."
                  )
                end
              end

              form_with(
                model: cancellation,
                url: "#cancel-subscription",
                builder: NitroKit::FormBuilder,
                id: "gallery-billing-cancellation-form",
                data: { turbo_frame: "gallery-billing-frame" }
              ) do |form|
                form.group do
                  form.field(
                    :reason,
                    as: :radio_group,
                    label: "Why are you cancelling?",
                    description: "Choose the closest reason. This does not change the cancellation date.",
                    options: CANCELLATION_REASONS,
                    required: true,
                    disabled:
                  )
                  form.field(
                    :feedback,
                    as: :textarea,
                    label: "Additional feedback",
                    description: "Optional, up to 500 characters.",
                    disabled:
                  )
                  form.field(
                    :confirmed,
                    as: :checkbox,
                    label: "I understand paid features end on August 1, 2026",
                    required: true,
                    disabled:
                  )
                  form.submit(
                    disabled ? "Cancelling plan…" : "Cancel Team plan",
                    id: "gallery-billing-cancellation-submit",
                    variant: :destructive,
                    disabled:,
                    data: { turbo_submits_with: "Cancelling plan…" }
                  )
                end
              end
            end
          end
          zone.escape NitroKit::Button.new(
            "Keep Team plan",
            id: "gallery-billing-cancellation-keep",
            href: entry_path(entry, state: "plans")
          )
        end
      end

      def render_cancelled
        render NitroKit::Card.new(id: "gallery-billing-cancelled-card") do |card|
          card.title("Cancellation scheduled", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Alert.new(id: "gallery-billing-cancelled", variant: :success) do |alert|
                alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-billing-cancelled-icon"))
                alert.title("Team plan ends August 1, 2026")
                alert.description("No further charges are scheduled. You can reactivate before the period ends without losing settings.")
              end
              render NitroKit::DetailsTable.new(
                cancellation_example(invalid: false),
                data: { gallery: "billing-cancellation-summary" }
              ) do |details|
                details.field(:reference, value: "cancel_2026_07_13_analytical_engines")
                details.field(:reason) { |reason| plain reason.humanize }
                details.field(:access_after_cancellation, value: "Starter plan with three active members")
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::Button.new(
              "Reactivate Team plan",
              id: "gallery-billing-reactivate",
              href: "#reactivate",
              variant: :primary
            )
          end
        end
      end

      def render_mobile_overview
        render NitroKit::Card.new(id: "gallery-billing-mobile-card") do |card|
          card.title("Team plan for Analytical Engines — Research and Production", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
                render NitroKit::Badge.new("Active", id: "gallery-billing-mobile-status", color: :success)
              end
              render NitroKit::DetailsTable.new(
                billing_overview,
                data: { gallery: "billing-mobile-summary" }
              ) do |details|
                details.fields(:next_invoice, :receipt_destination, :payment_method)
              end
              p do
                "Changing or cancelling the plan affects 18 active members, two pending invitations, automated " \
                  "audit exports, and seven connected deployment environments."
              end
            end
          end
          card.divider
          card.footer do
            render NitroKit::ButtonGroup.new(id: "gallery-billing-mobile-actions", label: "Billing actions") do |group|
              group.button(
                "Payment method",
                id: "gallery-billing-mobile-payment",
                href: entry_path(entry, state: "payment-method"),
                variant: :primary
              )
              group.button(
                "Invoices",
                id: "gallery-billing-mobile-invoices",
                href: entry_path(entry, state: "invoices")
              )
            end
          end
        end
      end

      def payment_method_example(invalid:)
        attributes = if invalid
          {
            cardholder_name: "",
            card_number: "4242",
            expiry: "7/26",
            billing_email: "not-an-email",
            postal_code: ""
          }
        else
          {
            cardholder_name: "Ada Lovelace",
            card_number: "4242424242424242",
            expiry: "08/28",
            billing_email: "accounts-payable+analytical-engines@example.test",
            postal_code: "SW1A 1AA"
          }
        end

        Gallery::Forms::PaymentMethod.new(**attributes).tap { |form| form.validate if invalid }
      end

      def billing_overview
        BillingOverview.new(
          next_invoice: "$49.00 USD on August 1, 2026",
          receipt_destination: "accounts-payable+international-research-and-production@example.test",
          payment_method: "Corporate Visa ending in 4242, expiring August 2026"
        )
      end

      def cancellation_example(invalid:)
        attributes = if invalid
          { reason: nil, feedback: "x" * 501, confirmed: false }
        else
          {
            reason: "temporary_pause",
            feedback: "Our research project pauses for one quarter. We expect to return in November.",
            confirmed: true
          }
        end

        Gallery::Forms::SubscriptionCancellation.new(**attributes).tap { |form| form.validate if invalid }
      end


      def state_description
        {
          "plans" => "Three plan choices expose pricing, features, current state, and upgrade actions.",
          "payment-method" => "A complete replacement-card form preserves native payment autocomplete semantics.",
          "payment-validation" => "Invalid card, expiry, email, and address values connect errors to their controls.",
          "payment-loading" => "Every payment control and the submitting action are disabled while Turbo saves.",
          "payment-updated" => "A deterministic success outcome confirms what changed and when the card is charged.",
          "invoices" => "Dense invoice history retains native records plus a final-page boundary and omitted pagination range.",
          "invoice-detail" => "Billing metadata, tax treatment, line items, totals, and document actions form one record.",
          "invoice-empty" => "A free workspace explains why no billing records exist and offers a useful next step.",
          "cancellation" => "Reason, feedback, explicit consent, impact copy, and a safe exit precede cancellation.",
          "cancellation-validation" => "Missing reason and consent plus excessive feedback produce connected errors.",
          "cancellation-loading" => "The destructive form cannot change while cancellation is being recorded.",
          "cancelled" => "The outcome names the final date, downgrade behavior, reference, and recovery action.",
          "mobile" => "Long workspace, email, payment, and impact copy pressure a narrow billing summary."
        }.fetch(state)
      end

      def plan_price(plan)
        return "$0 forever" if plan.price_cents.zero?

        "#{format_amount(plan.price_cents, "USD")} per #{plan.interval}"
      end

      def format_amount(cents, currency)
        symbol = currency == "USD" ? "$" : "#{currency} "
        "#{symbol}#{Kernel.format("%.2f", cents / 100.0)}"
      end

      def invoice_status_color(status)
        { paid: :success, refunded: :warning }.fetch(status, :neutral)
      end
    end
  end
end
