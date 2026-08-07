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
                  icon: :copy,
                  variant: :ghost,
                  size: :sm,
                  aria: { label: "Copy account identifier" }
                )
              end
            end
            sample("Long explanation", slug: "long") do
              render_tip(
                "gallery-tooltip-long",
                "Only workspace owners can rotate this credential; active integrations continue using the old value until the rotation completes."
              )
            end
            sample("Plain HTML trigger", slug: "html-trigger") do
              render NitroKit::Tooltip.new(
                id: "gallery-tooltip-html",
                content: "Deploys pause while the incident review is open."
              ) do |tooltip|
                tooltip.trigger("Deploys paused", as: :span)
              end
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

        example_section(
          "Trigger composition",
          slug: "tooltip-trigger-composition",
          description: "Links use the Button path directly; mutation forms and compound triggers receive Tooltip-owned attributes explicitly."
        ) do
          example("Existing actions", slug: "tooltip-existing-actions", layout: :matrix) do
            sample("Link", slug: "link") do
              render NitroKit::Tooltip.new(
                id: "gallery-tooltip-link",
                content: "Read the deployment runbook in a new tab."
              ) do |tooltip|
                tooltip.trigger("Deployment runbook", href: "#runbook", icon_end: :external_link)
              end
            end

            sample("Rails mutation", slug: "button-to") do
              render NitroKit::Tooltip.new(
                id: "gallery-tooltip-button-to",
                content: "Revoking the token immediately rejects new requests."
              ) do |tooltip|
                tooltip.trigger(as: :custom) do |attributes|
                  render NitroKit::ButtonTo.new(
                    "Revoke token",
                    href: "#revoke-token",
                    method: :delete,
                    variant: :destructive,
                    button_html: attributes.html,
                    button_aria: attributes.aria,
                    button_data: attributes.data
                  )
                end
              end
            end

            sample("Dialog trigger", slug: "dialog") do
              render NitroKit::Tooltip.new(
                id: "gallery-tooltip-dialog",
                content: "Review release details before publishing."
              ) do |tooltip|
                tooltip.trigger(as: :custom) do |attributes|
                  render NitroKit::Dialog.new(id: "gallery-tooltip-release-dialog") do |dialog|
                    dialog.trigger(
                      "Review release",
                      html: attributes.html,
                      aria: attributes.aria,
                      data: attributes.data
                    )
                    dialog.panel(title: "Publish release 2.0?") do
                      dialog.close_button(label: "Keep as draft")
                    end
                  end
                end
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
