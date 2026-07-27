module Gallery
  module Components
    class ToastPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/toast.rb"
      end

      def api_note
        "NitroKit::Toast.new(id:, duration:) { |toast| toast.item(id:) }"
      end

      def component_template
        example_section(
          "Variants",
          slug: "toast-variants",
          description: "Every notification intent renders as explicit server-owned markup. The list is addressable as <toast id>-list so Turbo Streams can append items."
        ) do
          example("Intent stack", slug: "toast-intent-stack", mode: :full_width) do
            render NitroKit::Toast.new(
              duration: 600_000,
              label: "Variant examples",
              id: "gallery-toast-variants"
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
                id: "gallery-toast-title-only"
              ) do |toast|
                toast.item(title: "Workspace saved", id: "gallery-toast-workspace-saved")
              end
            end
            sample("Permanent", slug: "permanent") do
              render NitroKit::Toast.new(
                label: "Permanent notification",
                id: "gallery-toast-permanent"
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
                id: "gallery-toast-timed"
              ) do |toast|
                toast.item(title: "Focus keeps this notification visible")
              end
            end
            sample("Block content", slug: "block") do
              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Block notification",
                id: "gallery-toast-block"
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
                id: "gallery-toast-long"
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
              id: "gallery-toast-flash"
            )
          end
        end

        example_section(
          "Controller to screen",
          slug: "toast-controller-to-screen",
          description: "Rails flash is the whole feedback contract. Render NitroKit::Toast::FlashMessages once in the application layout, set ordinary flash in the controller, and never add a client-side notification store for a server outcome."
        ) do
          example(
            "Flash lifecycle",
            slug: "toast-flash-lifecycle",
            description: "A successful action redirects with status: :see_other (303) and flash[:success], which Turbo follows so the message renders on the next page. A failed action never redirects: it sets flash.now and re-renders with status: :unprocessable_entity (422), which Turbo renders in place. Severity keys map notice to the default presentation, alert and error to error, and success, warning, and info to their matching variants; an unknown key falls back to the default presentation.",
            code: Gallery::SourceCode.from_method(method(:flash_lifecycle_recipe))
          ) do
            render NitroKit::Toast.new(
              duration: 600_000,
              label: "Flash lifecycle result",
              id: "gallery-toast-lifecycle"
            ) do |toast|
              toast.item(
                title: "Project created",
                description: "Rendered from flash[:success] after a 303 redirect.",
                variant: :success
              )
              toast.item(
                title: "Payment method was declined",
                description: "Rendered from flash.now[:alert] with the 422 re-render of the form.",
                variant: :error
              )
            end
          end

          example(
            "Region and announcement",
            slug: "toast-region-announcement",
            description: "The region is section[data-nk=toast] with role=region, aria-live=polite, and the label passed as label:. Each notification is li[data-nk=toast-item] with aria-atomic=true and role=status, except the error variant, which uses role=alert so assistive technology interrupts. Every item is data-turbo-temporary so a cached page never replays old feedback, while the region survives and its ol stays addressable as the toast id plus \"-list\" for a Turbo Stream append. duration: is the auto-dismiss timer in milliseconds; it pauses on hover and focus, and dismissible: false keeps a notice on screen until the person dismisses the page."
          ) do
            render NitroKit::Toast.new(
              duration: 600_000,
              label: "Announcement examples",
              id: "gallery-toast-announcement"
            ) do |toast|
              toast.item(
                title: "Polite status",
                description: "role=status waits for a pause in speech.",
                variant: :success
              )
              toast.item(
                title: "Assertive alert",
                description: "role=alert interrupts, so it is reserved for the error variant.",
                variant: :error
              )
            end
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
              id: "gallery-toast-integration-result"
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

      # The documented controller-to-screen path, kept as real Ruby so the Code
      # tab above extracts it. The gallery never calls it: an application owns
      # the layout, the controller, and the routes it names.
      def flash_lifecycle_recipe
        # app/views/layouts/application.rb renders the region once per page, so
        # every action reaches the same one. Nothing else renders a Toast.
        render NitroKit::Toast::FlashMessages.new(flash: flash, duration: 5_000)

        # app/controllers/projects_controller.rb#create, when the record saves.
        # 303 so Turbo follows the redirect after a non-GET request; the flash
        # survives it and renders on the next page.
        redirect_to(@project, status: :see_other, flash: { success: "Project created" })

        # The same action, when validation fails. No redirect, so flash.now, and
        # 422 so Turbo renders the response in place instead of ignoring it.
        flash.now[:alert] = "Project could not be created"
        render(UI::Projects::New.new(@project), status: :unprocessable_entity)

        # A Turbo Stream that neither redirects nor re-renders appends to the
        # region's list, addressable as the toast id plus "-list".
        turbo_stream.append("nk-toast-list") do
          render NitroKit::Toast::Item.new(title: "Import finished", variant: :success)
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
