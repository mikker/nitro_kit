module Gallery
  module Components
    class DropzonePage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/dropzone.rb"
      end

      def api_note
        "NitroKit::Dropzone.new(id:, name:, presentation:, inline:, direct_upload:, multiple:, accept:, max_files:, max_bytes:)"
      end

      def component_template
        example_section(
          "Upload modes",
          slug: "dropzone-modes",
          description: "Both modes retain a labelled native file input and ordinary multipart form submission."
        ) do
          example(
            "Active Storage direct upload",
            slug: "dropzone-direct-upload",
            description: "Choose files, then save to process them. The receipt appears here and the uploader clears for the next batch.",
            code: Gallery::SourceCode.from_method(Gallery::UploadPreview.instance_method(:direct_form))
          ) do
            render Gallery::UploadPreview.new(mode: "direct")
          end

          example(
            "Ordinary multipart upload",
            slug: "dropzone-multipart",
            description: "Files travel with the form request. Processing shows a receipt and clears only this preview.",
            code: Gallery::SourceCode.from_method(Gallery::UploadPreview.instance_method(:multipart_form))
          ) do
            render Gallery::UploadPreview.new(mode: "multipart")
          end

          example(
            "Shared form uploads",
            slug: "dropzone-shared-form",
            description: "Both uploads are processed together. Saving clears both inputs and leaves the other examples alone.",
            code: Gallery::SourceCode.from_method(Gallery::UploadPreview.instance_method(:shared_form))
          ) do
            render Gallery::UploadPreview.new(mode: "shared")
          end
        end

        example_section(
          "Presentation",
          slug: "dropzone-presentation",
          description: "The default minimal presentation hides the native file input, so the drop target " \
            "is the only visible affordance. The input presentation keeps the native control visible beside it."
        ) do
          example(
            "Drop target only",
            slug: "dropzone-minimal",
            description: "The input stays operable, focusable, and named: its own label opens the file picker, " \
              "and the drop target wears the focus ring while the input has focus."
          ) do
            render NitroKit::Dropzone.new(
              id: "gallery-dropzone-minimal",
              name: "avatar[file]",
              label: "Replace the workspace avatar",
              description: "One PNG, no larger than 1 MB.",
              direct_upload: false,
              accept: "image/png",
              max_bytes: 1024 * 1024
            )
          end

          example(
            "Avatar upload",
            slug: "dropzone-avatar",
            description: "A small photo picker. Choose an image, then save to process it and reset the input.",
            code: Gallery::SourceCode.from_method(Gallery::UploadPreview.instance_method(:avatar_form))
          ) do
            render Gallery::UploadPreview.new(mode: "avatar")
          end

          example(
            "Table row upload",
            slug: "dropzone-compact",
            description: "A tiny attachment control for receipts and dense lists, with a larger touch target on mobile.",
            code: Gallery::SourceCode.from_method(Gallery::UploadPreview.instance_method(:compact_form))
          ) do
            render Gallery::UploadPreview.new(mode: "compact")
          end

          example(
            "Inline layout",
            slug: "dropzone-inline",
            description: "A compact horizontal drop target with the same file previews and keyboard support."
          ) do
            render NitroKit::Dropzone.new(
              id: "gallery-dropzone-inline",
              name: "attachments[files][]",
              label: "Upload attachments",
              description: "PNG, JPG or PDF, up to 10 MB each.",
              inline: true,
              direct_upload: false,
              multiple: true,
              accept: "image/png,image/jpeg,application/pdf",
              max_files: 5,
              max_bytes: 10 * 1024 * 1024
            )
          end

          example(
            "Visible native input",
            slug: "dropzone-native-input",
            description: "presentation: :input keeps the native file control visible beside the drop target."
          ) do
            render NitroKit::Dropzone.new(
              id: "gallery-dropzone-native-input",
              name: "attachment[file]",
              label: "Attach a document",
              description: "One PDF, no larger than 2 MB.",
              presentation: :input,
              direct_upload: false,
              accept: "application/pdf",
              max_bytes: 2 * 1024 * 1024
            )
          end
        end

        example_section(
          "Availability and constraints",
          slug: "dropzone-constraints",
          description: "Required, multiple, disabled, type, count, and byte limits are explicit Ruby options and native attributes."
        ) do
          example("Constraint states", slug: "dropzone-constraint-states", layout: :matrix) do
            sample("Required single file", slug: "required-single") do
              render NitroKit::Dropzone.new(
                id: "gallery-dropzone-required",
                name: "evidence[file]",
                label: "Choose one PDF",
                description: "The browser keeps this requirement without JavaScript.",
                direct_upload: false,
                accept: "application/pdf",
                max_bytes: 512 * 1024,
                required: true
              )
            end

            sample("Disabled", slug: "disabled") do
              render NitroKit::Dropzone.new(
                id: "gallery-dropzone-disabled",
                name: "archive[file]",
                label: "Archived upload",
                description: "Uploads are unavailable while this record is archived.",
                disabled: true
              )
            end
          end
        end
      end
    end
  end
end
