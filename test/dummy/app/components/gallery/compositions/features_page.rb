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
        render NitroKit::Grid.new(cols: "1 md:2", gap: 5, id: "gallery-features-grid") do
          selected_features.each_with_index do |feature, index|
            render NitroKit::Card.new(id: "gallery-feature-#{feature.id}") do |card|
              card.title(feature_title(feature, index), level: 2)
              card.body do
                render NitroKit::Flex.new(dir: :col, gap: 3, align: :start) do
                  render NitroKit::Icon.new(feature_icon(feature.category), size: :lg)
                  render NitroKit::Badge.new(feature.category.to_s.humanize, color: feature_color(feature.category))
                  p { feature.description }
                end
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

      def feature_icon(category)
        { foundation: :blocks, automation: :workflow, security: :shield_check, collaboration: :users }.fetch(category)
      end

      def features_title
        return "A complete interface foundation for distributed Rails teams with regulated international operations" if state == "long"

        "Everything needed to compose credible Rails products"
      end

      def pricing_path
        gallery_composition_path(slug: "pricing", state: "monthly")
      end

      def section_title = "Product capabilities"
      def section_description = "Overview, security, automation, collaboration, long-content, and narrow feature states."

      def state_description
        {
          "overview" => "Build application foundations, Rails-native workflows, accessible interactions, and shared team conventions.",
          "security" => "Keep interface state and accessibility contracts visible in stable, inspectable markup.",
          "automation" => "Use ordinary Rails forms and focused Hotwire behavior instead of replacing the framework.",
          "collaboration" => "Give engineers and coding agents one typed vocabulary for composing product interfaces.",
          "long" => "A complete interface foundation for distributed teams operating regulated production systems.",
          "mobile" => "Core product capabilities remain clear and readable on a narrow screen."
        }.fetch(state)
      end
    end
  end
end
