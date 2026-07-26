module Gallery
  module Components
    class DropzonePage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/dropzone.rb"
      end

      def api_note
        "NitroKit::Dropzone.new(id:, name:, direct_upload:, multiple:, accept:, max_files:, max_bytes:)"
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
            description: "Selection starts a direct upload, writes signed blob IDs, and keeps the form unavailable until uploads settle."
          ) do
            form_with(
              scope: :upload,
              url: gallery_upload_submissions_path,
              builder: NitroKit::FormBuilder,
              id: "gallery-dropzone-direct-form",
              data: { turbo: false }
            ) do |form|
              form.dropzone(
                :files,
                id: "gallery-dropzone-direct",
                label: "Upload supporting evidence",
                description: "Up to two text or PNG files, each no larger than 2 MB.",
                multiple: true,
                accept: "text/plain,image/png",
                max_files: 2,
                max_bytes: 2 * 1024 * 1024,
                required: true
              )
              form.submit("Save direct upload", id: "gallery-dropzone-direct-submit")
            end
          end

          example(
            "Ordinary multipart upload",
            slug: "dropzone-multipart",
            description: "With direct upload disabled, dropped and selected files stay on the native input for the normal form request."
          ) do
            form_with(
              scope: :upload,
              url: gallery_upload_submissions_path,
              builder: NitroKit::FormBuilder,
              id: "gallery-dropzone-multipart-form",
              data: { turbo: false }
            ) do |form|
              form.dropzone(
                :files,
                id: "gallery-dropzone-multipart",
                label: "Add source files",
                description: "Choose up to three text or PNG files.",
                direct_upload: false,
                multiple: true,
                accept: "text/plain,image/png",
                max_files: 3,
                max_bytes: 1024 * 1024
              )
              form.submit("Submit files", id: "gallery-dropzone-multipart-submit")
            end
          end

          example(
            "Shared form uploads",
            slug: "dropzone-shared-form",
            description: "Each Dropzone keeps the shared form unavailable only while its own upload is active."
          ) do
            form_with(
              scope: :upload,
              url: gallery_upload_submissions_path,
              builder: NitroKit::FormBuilder,
              id: "gallery-dropzone-shared-form",
              data: { turbo: false }
            ) do |form|
              form.group do
                form.dropzone(
                  :primary_file,
                  id: "gallery-dropzone-shared-primary",
                  label: "Upload primary evidence",
                  accept: "text/plain"
                )
                form.dropzone(
                  :secondary_file,
                  id: "gallery-dropzone-shared-secondary",
                  label: "Upload secondary evidence",
                  accept: "text/plain"
                )
                form.submit("Save both uploads", id: "gallery-dropzone-shared-submit")
                form.button(
                  "Unavailable action",
                  id: "gallery-dropzone-shared-disabled-submit",
                  type: :submit,
                  disabled: true
                )
              end
            end
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
