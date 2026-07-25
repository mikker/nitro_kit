module Gallery
  module Components
    class ConfirmDialogPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/confirm_dialog.rb"
      end

      def api_note
        "NitroKit::ConfirmDialog.new"
      end

      def component_template
        example_section(
          "Compact destructive confirmation",
          slug: "confirm-dialog-compact",
          description: "One layout-level dialog presents the message declared by an ordinary Turbo form."
        ) do
          example("Delete project", slug: "confirm-dialog-delete") do
            form(
              id: "gallery-confirm-dialog-form",
              action: "#confirmed",
              method: "get",
              data: {
                turbo_confirm: "Delete the Apollo project permanently?"
              }
            ) do
              render NitroKit::Button.new(
                "Delete project",
                type: :submit,
                variant: :destructive
              )
            end

            render NitroKit::ConfirmDialog.new(
              id: "gallery-confirm-dialog",
              confirm_label: "Delete project"
            )
          end
        end
      end
    end
  end
end
