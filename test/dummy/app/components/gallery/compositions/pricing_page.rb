module Gallery
  module Compositions
    class PricingPage < ScenarioPage
      private

      def render_scenario
        workspace_surface do
          render_header
          render_cadence
          render_plans
          render_comparison if state == "comparison"
          render_enterprise if state == "enterprise"
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: pricing_title,
          description: state_description,
          id: "gallery-pricing-header"
        ) do |header|
          header.actions(NitroKit::ButtonGroup.new(id: "gallery-pricing-actions", label: "Pricing page actions")) do |actions|
            actions.button("Compare features", href: entry_path(entry, state: "comparison"))
            actions.button("Contact sales", href: contact_path, variant: :primary)
          end
        end
      end

      def render_cadence
        render NitroKit::Toolbar.new(id: "gallery-pricing-cadence") do |toolbar|
          toolbar.leading do
            render NitroKit::Badge.new(
              annual? ? "Two months included" : "Change or cancel any time",
              color: annual? ? :success : :info
            )
          end
          toolbar.trailing do
            render NitroKit::ButtonGroup.new(label: "Billing cadence") do |actions|
              actions.button(
                "Monthly",
                href: entry_path(entry, state: "monthly"),
                variant: annual? ? :default : :primary,
                aria: { current: annual? ? nil : "page" }
              )
              actions.button(
                "Annual",
                href: entry_path(entry, state: "annual"),
                variant: annual? ? :primary : :default,
                aria: { current: annual? ? "page" : nil }
              )
            end
          end
        end
      end

      def render_plans
        render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-pricing-plan-grid") do
          Gallery::PublicData.plans.each do |plan|
            render NitroKit::Card.new(id: "gallery-pricing-plan-#{plan.id}") do |card|
              card.title(plan_name(plan), level: 2)
              card.body do
                render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
                  render NitroKit::Badge.new("Recommended", color: :success) if plan.highlighted
                  strong { plan_price(plan) }
                  p { plan.description }
                  ul { plan.features.each { |feature| li { feature } } }
                end
              end
              card.footer do
                render NitroKit::Button.new(
                  plan.monthly_cents.zero? ? "Start free" : "Choose #{plan.name}",
                  href: "#choose-#{plan.id}",
                  variant: plan.highlighted ? :primary : :default
                )
              end
            end
          end
        end
      end

      def render_comparison
        render NitroKit::DataSection.new(
          title: "Compare plans",
          description: "Product limits and entitlements remain caller-owned pricing data.",
          id: "gallery-pricing-comparison"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Plan comparison actions")) do |actions|
            actions.button("Download comparison", href: "#download-comparison")
          end
          section.table(NitroKit::Table.new(id: "gallery-pricing-comparison-table")) do |table|
            table.caption("Plan feature comparison")
            table.thead do
              table.tr do
                table.th("Capability")
                Gallery::PublicData.plans.each { |plan| table.th(plan.name) }
              end
            end
            table.tbody do
              comparison_rows.each do |capability, values|
                table.tr do
                  table.th(capability, scope: :row)
                  values.each { |value| table.td(value) }
                end
              end
            end
          end
        end
      end

      def render_enterprise
        render NitroKit::Alert.new(id: "gallery-pricing-enterprise", variant: :default) do |alert|
          alert.title("Enterprise agreements follow your procurement process")
          alert.description("Annual invoicing, security review, tax documentation, and data residency are agreed by the application team.")
        end
      end

      def comparison_rows
        [
          [ "Members", [ "3", "20", "Unlimited" ] ],
          [ "Audit history", [ "30 days", "180 days", "730 days" ] ],
          [ "Support", [ "Community", "Email", "Priority" ] ]
        ]
      end

      def annual?
        state == "annual"
      end

      def plan_price(plan)
        cents = annual? ? plan.annual_cents : plan.monthly_cents
        return "$0" if cents.zero?

        "$#{cents / 100} #{annual? ? "per year" : "per month"}"
      end

      def plan_name(plan)
        return plan.name unless state == "long" && plan.id == "scale"

        "Scale for International Research, Production, Reliability Engineering, Regulatory Operations, and Customer Support"
      end

      def pricing_title
        return "Pricing for distributed application teams operating regulated international production systems" if state == "long"

        "Simple plans for serious Rails applications"
      end

      def contact_path
        gallery_composition_path(slug: "contact", state: "form")
      end

      def composition_label = "Public pricing"
      def section_title = "Pricing and plan comparison"
      def section_description = "Monthly, annual, comparison, enterprise, long-content, and narrow pricing states."

      def state_description
        {
          "monthly" => "Monthly prices, included capabilities, and plan actions stay explicit.",
          "annual" => "Annual billing changes caller-owned amounts and cadence without changing component APIs.",
          "comparison" => "A semantic table compares durable plan entitlements across the same public page.",
          "enterprise" => "Procurement and security expectations remain product policy rather than component behavior.",
          "long" => "Long plan and organization language wraps without custom classes or truncation.",
          "mobile" => "The accepted grid owns narrow stacking while every plan remains available."
        }.fetch(state)
      end
    end
  end
end
