module Gallery
  module Components
    class RichTextAreaPage < ComponentPage
      include Phlex::Rails::Helpers::RichTextArea

      private

      def source_note
        "app/components/nitro_kit/rich_text_area.rb"
      end

      def api_note
        "NitroKit::Field.new(form, name, as: :rich_text) wraps NitroKit::RichTextArea.new(content)"
      end

      def component_template
        example_section(
          "Field composition",
          slug: "rich-text-area-field",
          description: "Field(as: :rich_text) is the expected path. The FormBuilder captures the " \
            "application's Action Text editor and Nitro owns only the label, description, and error contract."
        ) do
          example("FormBuilder rich text field", slug: "rich-text-area-form", mode: :full_width) do
            form_with(
              model: Gallery::Forms::ProjectBrief.new(name: "Aurora", brief: "<p>Ship the reporting rewrite.</p>"),
              scope: :project_brief,
              url: "#rich-text-area-form",
              builder: NitroKit::FormBuilder,
              id: "gallery-rich-text-form"
            ) do |form|
              form.group do
                form.field(:name, label: "Project name")
                form.field(
                  :brief,
                  as: :rich_text,
                  label: "Project brief",
                  description: "Shared with everyone who can see the project.",
                  required: true
                )
                form.submit("Save brief", id: "gallery-rich-text-save")
              end
            end
          end

          example("Invalid rich text field", slug: "rich-text-area-invalid", mode: :full_width) do
            invalid = Gallery::Forms::ProjectBrief.new(name: "Aurora", brief: "")
            invalid.validate

            form_with(
              model: invalid,
              scope: :rejected_brief,
              url: "#rich-text-area-invalid",
              builder: NitroKit::FormBuilder,
              id: "gallery-rich-text-invalid-form"
            ) do |form|
              form.field(
                :brief,
                as: :rich_text,
                label: "Project brief",
                description: "A brief is required before the project can be published."
              )
            end
          end
        end

        example_section(
          "Standalone editor",
          slug: "rich-text-area-standalone",
          description: "Outside a Field, RichTextArea wraps trusted Action Text output directly. " \
            "The editor owns its inputs, attachments, and behavior."
        ) do
          example("Action Text editor", slug: "rich-text-area-action-text", mode: :full_width) do
            editor = capture do
              rich_text_area(
                :announcement,
                :body,
                value: "<p>Maintenance window on Friday.</p>",
                id: "gallery-rich-text-standalone-editor"
              )
            end

            render NitroKit::RichTextArea.new(
              editor,
              id: "gallery-rich-text-standalone",
              aria: { label: "Announcement body" }
            )
          end
        end
      end
    end
  end
end
