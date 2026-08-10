module Gallery
  module Compositions
    class LandingPage < ScenarioPage
      private

      def render_scenario
        workspace_surface do
          render_header
          render_announcement if state == "announcement"
          render_results
          render_feature_summary
          render_customer_proof if state == "customer-proof"
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: landing_title,
          description: state_description,
          id: "gallery-landing-header"
        ) do |header|
          header.actions(NitroKit::ButtonGroup.new(id: "gallery-landing-actions", label: "Landing page actions")) do |actions|
            actions.button("View pricing", href: pricing_path)
            actions.button("Start building", href: "#start", variant: :primary)
          end
        end
      end

      def render_announcement
        render NitroKit::Alert.new(variant: :success, id: "gallery-landing-announcement") do |alert|
          alert.icon NitroKit::Icon.new(:sparkles)
          alert.title("Nitro Kit 2.0 is available")
          alert.description("The agent-native release adds typed layouts, application sections, and static themeable CSS.")
        end
      end

      def render_results
        render NitroKit::StatGrid.new(id: "gallery-landing-results") do |stats|
          stats.stat(key: :components, label: "Stock components", value: "40", detail: "Typed, direct Phlex APIs")
          stats.stat(key: :layouts, label: "Layout primitives", value: "3", detail: "Flex, Grid, and Container")
          stats.stat(key: :classes, label: "Required CSS classes", value: "0", detail: "Self-describing data contracts")
        end
      end

      def render_feature_summary
        render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-landing-feature-grid") do
          landing_features.each do |feature|
            render NitroKit::Card.new(id: "gallery-landing-feature-#{feature.id}") do |card|
              card.title(feature.title, level: 2)
              card.body do
                render NitroKit::Flex.new(dir: :col, gap: 3, align: :start) do
                  render NitroKit::Icon.new(landing_feature_icon(feature.id), size: :lg)
                  p { feature.description }
                end
              end
            end
          end
        end
      end

      def render_customer_proof
        render NitroKit::DataSection.new(
          title: "Built with application teams",
          description: "Teams use the same typed vocabulary across engineers, coding agents, and production Rails code.",
          id: "gallery-landing-proof"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Customer proof actions")) do |actions|
            actions.button("Read customer stories", href: "#stories")
          end
          section.table(NitroKit::Table.new(id: "gallery-landing-proof-table")) do |table|
            table.caption("Example customer outcomes")
            table.thead do
              table.tr do
                table.th("Organization")
                table.th("Outcome")
                table.th("Detail") unless state == "mobile"
              end
            end
            table.tbody do
              Gallery::PublicData.proof.each do |proof|
                table.tr do
                  table.th(proof.organization, scope: :row)
                  table.td(proof.result)
                  table.td(proof.detail) unless state == "mobile"
                end
              end
            end
          end
        end
      end

      def landing_features
        features = Gallery::PublicData.features.first(3)
        state == "mobile" ? features.first(2) : features
      end

      def landing_feature_icon(id)
        {
          "typed-components" => :blocks,
          "static-css" => :paintbrush,
          "rails-forms" => :list_checks,
          "accessible-contracts" => :badge_check
        }.fetch(id, :sparkles)
      end

      def landing_title
        return "Build verifiable Rails interfaces for International Research, Production, Reliability Engineering, and Customer Operations" if state == "long"

        "A UI kit Rails applications and agents can understand"
      end

      def pricing_path
        gallery_composition_path(slug: "pricing", state: "monthly")
      end

      def features_path
        gallery_composition_path(slug: "features", state: "overview")
      end

      def section_title = "Product landing page"
      def section_description = "Default, announcement, customer proof, long-content, and narrow public states."

      def state_description
        {
          "default" => "Compose polished Rails interfaces from typed Ruby components that agents can inspect and engineers can trust.",
          "announcement" => "Nitro Kit 2.0 brings typed layouts, application sections, and static themeable CSS.",
          "customer-proof" => "See how application teams use one component vocabulary across people, agents, and production Rails code.",
          "long" => "Build verifiable interfaces for large research, production, reliability, and customer operations teams.",
          "mobile" => "Build readable, accessible product flows that stay useful on every screen."
        }.fetch(state)
      end
    end
  end
end
