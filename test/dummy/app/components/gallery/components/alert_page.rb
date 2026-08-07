module Gallery
  module Components
    class AlertPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/alert.rb"
      end

      def api_note
        "NitroKit::Alert.new(variant:, title:, description:) { |alert| alert.title; alert.description }"
      end

      def component_template
        example_section(
          "Variants",
          slug: "alert-variants",
          description: "Every semantic intent stays visible in data. live: defaults to :off, so these static alerts render without a live region role."
        ) do
          example(
            "Intent matrix",
            slug: "alert-intent-matrix",
            mode: :full_width,
            layout: :matrix
          ) do
            Gallery::Data.alert_variants.each do |alert|
              sample(alert.variant.to_s.humanize, slug: alert.slug) do
                render_alert(alert)
              end
            end
          end
        end

        example_section(
          "Content modes",
          slug: "alert-content",
          description: "Title, description, icon, and nested content are optional independent slots."
        ) do
          example("Slot combinations", slug: "alert-slot-combinations", layout: :matrix) do
            sample("Title only", slug: "title-only") do
              render NitroKit::Alert.new(id: "gallery-alert-title-only") do |alert|
                alert.title("Scheduled maintenance")
              end
            end
            sample("Description only", slug: "description-only") do
              render NitroKit::Alert.new(id: "gallery-alert-description-only") do |alert|
                alert.description("New sign-ins require a recovery code for the next 24 hours.")
              end
            end
            sample("Icon and title", slug: "icon-title") do
              render NitroKit::Alert.new(id: "gallery-alert-icon-title", variant: :success) do |alert|
                alert.icon(NitroKit::Icon.new(:circle_check, id: "gallery-alert-icon-title-icon"))
                alert.title("All systems operational")
              end
            end
            sample("Constructor text", slug: "constructor-text") do
              render NitroKit::Alert.new(
                id: "gallery-alert-constructor-text",
                variant: :info,
                title: "Scheduled maintenance",
                description: "Deploys pause Thursday between 02:00 and 02:10 UTC."
              )
            end
            sample("Nested status", slug: "nested-status") do
              render NitroKit::Alert.new(id: "gallery-alert-nested-status") do |alert|
                alert.title("Production release")
                alert.description do
                  render NitroKit::Badge.new(
                    "Deploying",
                    id: "gallery-alert-deploying-badge",
                    color: :info,
                    size: :sm
                  )
                end
              end
            end
          end
        end

        example_section(
          "Live announcement",
          slug: "alert-live",
          description: "live: :polite renders role=status and live: :assertive renders role=alert, so alerts inserted by Turbo are announced; the :off default stays silent."
        ) do
          example("Live modes", slug: "alert-live-modes", layout: :matrix) do
            sample("Polite", slug: "polite") do
              render NitroKit::Alert.new(
                id: "gallery-alert-live-polite",
                variant: :info,
                live: :polite,
                title: "Export ready",
                description: "The workspace export finished and is ready to download."
              )
            end
            sample("Assertive", slug: "assertive") do
              render NitroKit::Alert.new(
                id: "gallery-alert-live-assertive",
                variant: :error,
                live: :assertive,
                title: "Connection lost",
                description: "Changes stopped saving; check the network before continuing."
              )
            end
          end
        end

        example_section(
          "Long content",
          slug: "alert-long-content",
          description: "Operational messages remain readable when product copy is specific and multi-line."
        ) do
          example("Detailed incident", slug: "alert-detailed-incident") do
            render NitroKit::Alert.new(id: "gallery-alert-long", variant: :error) do |alert|
              alert.icon(NitroKit::Icon.new(:circle_x, id: "gallery-alert-long-icon"))
              alert.title("Production deployment could not complete after the database migration timed out")
              alert.description do
                "Existing traffic is still served by release 2026.07.12. Review the migration log, resolve the " \
                  "lock contention, and retry the deploy when the primary database is healthy."
              end
            end
          end
        end

        example_section(
          "Notification composition",
          slug: "alert-notifications",
          description: "Card, Alert, Icon, Badge, AvatarStack, and Avatar compose into a realistic release notice."
        ) do
          example("Release notification", slug: "alert-release-notification") do
            render NitroKit::Card.new(id: "gallery-alert-notification-card") do |card|
              card.title("Release 2026.07.13", level: 3)
              card.body do
                render NitroKit::Alert.new(
                  id: "gallery-alert-notification-success",
                  variant: :success
                ) do |alert|
                  alert.icon(
                    NitroKit::Icon.new(:circle_check, id: "gallery-alert-notification-success-icon")
                  )
                  alert.title("Production deployment completed")
                  alert.description("The release is serving all workspaces in Europe and North America.")
                end
              end
              card.footer do
                render NitroKit::Badge.new(
                  "Production",
                  id: "gallery-alert-notification-badge",
                  color: :success,
                  size: :sm
                )
                render NitroKit::AvatarStack.new(
                  id: "gallery-alert-notification-reviewers",
                  size: :sm,
                  label: "Release reviewers"
                ) do |stack|
                  stack.avatar(alt: "Ada Lovelace", fallback: "AL", id: "gallery-alert-reviewer-ada")
                  stack.avatar(alt: "Grace Hopper", fallback: "GH", id: "gallery-alert-reviewer-grace")
                  stack.overflow(2)
                end
              end
            end
          end
        end
      end

      def render_alert(alert)
        render NitroKit::Alert.new(
          id: "gallery-alert-variant-#{alert.slug}",
          variant: alert.variant
        ) do |component|
          component.icon(
            NitroKit::Icon.new(alert.icon, id: "gallery-alert-variant-#{alert.slug}-icon")
          )
          component.title(alert.title)
          component.description(alert.description)
        end
      end
    end
  end
end
