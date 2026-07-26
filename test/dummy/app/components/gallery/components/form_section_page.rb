module Gallery
  module Components
    class FormSectionPage < ComponentPage
      private

      def component_template
        example_section(
          "Rails-owned complete forms",
          slug: "form-section-pressure",
          description: "The section frames one complete form and an optional typed status without owning fields, models, routes, or submission policy."
        ) do
          example("Minimal form", slug: "form-section-minimal") do
            render_form_section(
              id: "gallery-form-section-minimal",
              title: "Workspace name",
              fields: [ [ :name, "Workspace name" ] ]
            )
          end

          example("Validation status", slug: "form-section-validation") do
            render NitroKit::FormSection.new(
              title: "Profile",
              description: "Public details shown to workspace members.",
              id: "gallery-form-section-validation"
            ) do |section|
              section.status NitroKit::Alert.new(variant: :error, id: "gallery-form-section-validation-status") do |alert|
                alert.title("Profile was not saved")
                alert.description("Correct the highlighted name and email fields.")
              end
              section.form do
                form_with(url: "#profile", scope: :profile, builder: NitroKit::FormBuilder, id: "gallery-form-section-validation-form") do |form|
                  form.group do
                    form.field(:name, label: "Display name", value: "", errors: [ "cannot be blank" ], required: true)
                    form.field(:email, as: :email, label: "Email", value: "not-an-email", errors: [ "is invalid" ], required: true)
                    form.submit("Save profile")
                  end
                end
              end
            end
          end

          example("Success status", slug: "form-section-success") do
            render NitroKit::FormSection.new(
              title: "Notification settings",
              description: "Choose which operational changes should send email.",
              id: "gallery-form-section-success"
            ) do |section|
              section.status NitroKit::Alert.new(variant: :success, id: "gallery-form-section-success-status") do |alert|
                alert.title("Notification settings saved")
                alert.description("New incidents and weekly summaries will be delivered to ada@example.test.")
              end
              section.form do
                form_with(url: "#notifications", scope: :notifications, builder: NitroKit::FormBuilder, id: "gallery-form-section-success-form") do |form|
                  form.group do
                    form.field(:incidents, as: :switch, label: "Incident alerts", checked: true)
                    form.field(:summaries, as: :switch, label: "Weekly summaries", checked: true)
                    form.submit("Save notifications")
                  end
                end
              end
            end
          end

          example("Dense long form", slug: "form-section-dense", mode: :full_width, density: :compact) do
            render NitroKit::Container.new(size: :lg, id: "gallery-form-section-dense-container") do
              render_form_section(
                id: "gallery-form-section-dense",
                title: "International Research and Reliability workspace profile",
                description: "Long labels, guidance, and a complete caller-owned form exercise the boundary without teaching the section about a Rails model.",
                fields: [
                  [ :name, "Official workspace name" ],
                  [ :billing_email, "Billing and compliance contact email" ],
                  [ :legal_entity, "Contracting legal entity" ],
                  [ :data_region, "Primary encrypted data residency region" ],
                  [ :retention, "Audit event retention policy acknowledgement" ]
                ]
              )
            end
          end
        end
      end

      def render_form_section(id:, title:, fields:, description: nil)
        render NitroKit::FormSection.new(title:, description:, id:) do |section|
          section.form do
            form_with(url: "##{id}", scope: :workspace, builder: NitroKit::FormBuilder, id: "#{id}-form") do |form|
              form.group do
                fields.each do |name, label|
                  form.field(name, id: "#{id}-#{name}", label:, required: true)
                end
                form.submit("Save changes")
              end
            end
          end
        end
      end

      def source_note
        "The complete form element is a named leaf. Rails keeps naming, CSRF, model errors, multipart behavior, and submission semantics."
      end

      def api_note
        "Supply the required title and optional description through constructor text or matching compound methods. form requires exactly one block that renders a complete form. status accepts at most one NitroKit::Alert before it."
      end
    end
  end
end
