module Gallery
  module Components
    class TooltipPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/tooltip.rb"
      end

      def api_note
        "NitroKit::Tooltip.new(id:, content:) { |tooltip| tooltip.trigger }"
      end

      def component_template
        example_section(
          "Placements",
          slug: "tooltip-placements",
          description: "CSS exposes each description on hover and focus; a tiny controller only adds Escape dismissal."
        ) do
          example("Placement matrix", slug: "tooltip-placement-matrix", layout: :matrix) do
            NitroKit::Tooltip::PLACEMENTS.each do |placement|
              sample(placement.to_s.humanize, slug: placement.to_s) do
                render_tip(
                  "gallery-tooltip-#{placement}",
                  "This explanation opens on the #{placement} edge.",
                  placement:
                )
              end
            end
          end
        end

        example_section(
          "Trigger treatments",
          slug: "tooltip-triggers",
          description: "Tooltip owns a real Button trigger, including icon-only accessible actions."
        ) do
          example("Button treatments", slug: "tooltip-button-treatments", layout: :matrix) do
            sample("Primary", slug: "primary") do
              render NitroKit::Tooltip.new(
                id: "gallery-tooltip-primary",
                content: "Creates a new production deployment."
              ) do |tooltip|
                tooltip.trigger("Deploy", variant: :primary)
              end
            end
            sample("Icon only", slug: "icon-only") do
              render NitroKit::Tooltip.new(
                id: "gallery-tooltip-icon",
                content: "Copy the account identifier."
              ) do |tooltip|
                tooltip.trigger(
                  variant: :ghost,
                  size: :sm,
                  aria: { label: "Copy account identifier" }
                ) { "Copy" }
              end
            end
            sample("Long explanation", slug: "long") do
              render_tip(
                "gallery-tooltip-long",
                "Only workspace owners can rotate this credential; active integrations continue using the old value until the rotation completes."
              )
            end
          end
        end

        example_section(
          "Settings composition",
          slug: "tooltip-settings",
          description: "A contextual explanation composes beside a sensitive setting without wrapping a raw focus target."
        ) do
          example("API credential", slug: "tooltip-api-credential") do
            render NitroKit::Card.new(id: "gallery-tooltip-api-card") do |card|
              card.title("Production credential", level: 3)
              card.body do
                render NitroKit::Badge.new(
                  "Read and write",
                  id: "gallery-tooltip-api-access",
                  color: :warning,
                  size: :sm
                )
                p { "nk_live_7P3F… was last used today at 08:31 UTC." }
              end
              card.footer do
                render NitroKit::Tooltip.new(
                  id: "gallery-tooltip-rotate-key",
                  content: "Rotation immediately reveals a new secret once."
                ) do |tooltip|
                  tooltip.trigger("How rotation works")
                end
                render NitroKit::Button.new(
                  "Rotate credential",
                  id: "gallery-tooltip-rotate-action",
                  variant: :destructive
                )
              end
            end
          end
        end
      end

      def render_tip(id, content, placement: :top)
        render NitroKit::Tooltip.new(id:, content:, placement:) do |tooltip|
          tooltip.trigger(placement.to_s.humanize)
        end
      end
    end
  end
end
