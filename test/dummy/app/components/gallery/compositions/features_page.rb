module Gallery
  module Compositions
    class FeaturesPage < ScenarioPage
      private

      def render_scenario
        workspace_surface do
          render_header
          render_product_facts
          render_features
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: features_title,
          description: state_description,
          id: "gallery-features-header"
        ) do |header|
          header.actions(NitroKit::ButtonGroup.new(id: "gallery-features-actions", label: "Features page actions")) do |actions|
            actions.button("View pricing", href: pricing_path)
            actions.button("Read the guide", href: "#guide", variant: :primary)
          end
        end
      end

      def render_product_facts
        render NitroKit::StatGrid.new(id: "gallery-features-facts") do |stats|
          stats.stat(key: :ruby, label: "Public API", value: "Ruby", detail: "Direct Phlex composition")
          stats.stat(key: :styles, label: "Runtime styling", value: "0", detail: "Static gem-owned CSS")
          stats.stat(key: :helpers, label: "Nitro ERB helpers", value: "0", detail: "Rails helpers remain available")
        end
      end

      def render_features
        render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-features-grid") do
          selected_features.each_with_index do |feature, index|
            render NitroKit::Card.new(id: "gallery-feature-#{feature.id}") do |card|
              card.title(feature_title(feature, index), level: 2)
              card.body do
                render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
                  render NitroKit::Badge.new(feature.category.to_s.humanize, color: feature_color(feature.category))
                  p { feature.description }
                end
              end
              card.footer do
                render NitroKit::Button.new(
                  "Learn about #{feature.title.downcase}",
                  href: "#feature-#{feature.id}"
                )
              end
            end
          end
        end
      end

      def selected_features
        records = Gallery::PublicData.features
        case state
        when "security"
          records.select { |feature| feature.category == :security }
        when "automation"
          records.select { |feature| feature.category == :automation }
        when "collaboration"
          records.select { |feature| feature.category == :collaboration }
        when "mobile"
          records.first(3)
        else
          records
        end
      end

      def feature_title(feature, index)
        return feature.title unless state == "long" && index.zero?

        "Typed components for International Research, Production, Reliability Engineering, and Customer Operations"
      end

      def feature_color(category)
        { foundation: :info, automation: :success, security: :warning, collaboration: :neutral }.fetch(category)
      end

      def features_title
        return "A complete interface foundation for distributed Rails teams with regulated international operations" if state == "long"

        "Everything needed to compose credible Rails products"
      end

      def pricing_path
        gallery_composition_path(slug: "pricing", state: "monthly")
      end

      def composition_label = "Public features"
      def section_title = "Product capabilities"
      def section_description = "Overview, security, automation, collaboration, long-content, and narrow feature states."

      def state_description
        {
          "overview" => "The complete product vocabulary is grouped as caller-owned public feature data.",
          "security" => "Security-focused content uses the same cards and layouts without a product-specific component.",
          "automation" => "Rails forms and Hotwire behavior remain visible as concrete automation capabilities.",
          "collaboration" => "Application ownership stays central when agents and engineers share one component vocabulary.",
          "long" => "Long product language wraps through the same restrained public hierarchy.",
          "mobile" => "A focused subset complements the narrow composition surface without a mobile component API."
        }.fetch(state)
      end
    end
  end
end
