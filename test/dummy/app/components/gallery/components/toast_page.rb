module Gallery
  module Components
    class ToastPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/toast.rb"
      end

      def api_note
        "NitroKit::Toast.new(duration:) { |toast| toast.item }"
      end

      def component_template
        example_section(
          "Variants",
          slug: "toast-variants",
          description: "Every notification intent renders as explicit server-owned markup."
        ) do
          example("Intent stack", slug: "toast-intent-stack", mode: :full_width) do
            render NitroKit::Toast.new(
              duration: 600_000,
              label: "Variant examples",
              html: { id: "gallery-toast-variants" }
            ) do |toast|
              NitroKit::Toast::Item::VARIANTS.each do |variant|
                toast.item(
                  title: variant.to_s.humanize,
                  description: toast_description(variant),
                  variant:
                )
              end
            end
          end
        end

        example_section(
          "Content and dismissal",
          slug: "toast-content",
          description: "Title, description, block content, permanent notices, and long messages are independent."
        ) do
          example("Content combinations", slug: "toast-content-combinations", layout: :matrix) do
            sample("Title only", slug: "title-only") do
              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Title only notification",
                html: { id: "gallery-toast-title-only" }
              ) do |toast|
                toast.item(title: "Workspace saved")
              end
            end
            sample("Permanent", slug: "permanent") do
              render NitroKit::Toast.new(
                label: "Permanent notification",
                html: { id: "gallery-toast-permanent" }
              ) do |toast|
                toast.item(
                  description: "A workspace owner must acknowledge this billing change.",
                  variant: :warning,
                  dismissible: false
                )
              end
            end
            sample("Timed pause", slug: "timed-pause") do
              render NitroKit::Toast.new(
                duration: 1_200,
                label: "Timed notification",
                html: { id: "gallery-toast-timed" }
              ) do |toast|
                toast.item(title: "Focus keeps this notification visible")
              end
            end
            sample("Block content", slug: "block") do
              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Block notification",
                html: { id: "gallery-toast-block" }
              ) do |toast|
                toast.item(title: "Deployment details", variant: :info) do
                  p { "Release 2026.07.13 is healthy in fra1 and iad1." }
                  render NitroKit::Badge.new(
                    "Production",
                    id: "gallery-toast-environment",
                    color: :success,
                    size: :sm
                  )
                end
              end
            end
            sample("Long error", slug: "long-error") do
              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Long error notification",
                html: { id: "gallery-toast-long" }
              ) do |toast|
                toast.item(
                  title: "The production deployment could not be promoted",
                  description: "The release remains healthy in staging, but the primary database rejected the migration lock. Review the deployment log before retrying.",
                  variant: :error
                )
              end
            end
          end
        end

        example_section(
          "Rails flash",
          slug: "toast-flash",
          description: "Flash rendering receives explicit data and never reaches through a template context."
        ) do
          example("Flash severity mapping", slug: "toast-flash-messages") do
            render NitroKit::Toast::FlashMessages.new(
              flash: {
                notice: "Welcome back, Ada.",
                success: "Production settings were saved.",
                warning: "The payment method expires next month.",
                alert: "Your session expired; sign in again."
              },
              duration: 600_000,
              label: "Rails flash messages",
              html: { id: "gallery-toast-flash" }
            )
          end
        end

        example_section(
          "Action result composition",
          slug: "toast-action-result",
          description: "A realistic settings result keeps source data, action controls, and notifications explicit."
        ) do
          example("Saved integration", slug: "toast-saved-integration") do
            render NitroKit::Card.new(id: "gallery-toast-integration-card") do |card|
              card.title("Slack integration", level: 3)
              card.body do
                render NitroKit::Badge.new(
                  "Connected",
                  id: "gallery-toast-integration-status",
                  color: :success
                )
                p { "Deployment notifications post to #operations." }
              end
              card.footer do
                render NitroKit::Button.new(
                  "Configure",
                  id: "gallery-toast-configure",
                  variant: :default
                )
              end
            end
            render NitroKit::Toast.new(
              duration: 600_000,
              label: "Integration result",
              html: { id: "gallery-toast-integration-result" }
            ) do |toast|
              toast.item(
                title: "Slack settings saved",
                description: "New deployment notifications will use #operations.",
                variant: :success
              )
            end
          end
        end
      end

      def toast_description(variant)
        {
          default: "Workspace preferences were updated.",
          info: "A new release is ready for verification.",
          success: "The production deployment completed.",
          warning: "The payment method expires next month.",
          error: "The deployment stopped during migration."
        }.fetch(variant)
      end
    end
  end
end
