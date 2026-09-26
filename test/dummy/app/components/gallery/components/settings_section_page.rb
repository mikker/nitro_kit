module Gallery
  module Components
    class SettingsSectionPage < ComponentPage
      private

      def component_template
        example_section(
          "Rails-owned complete forms",
          slug: "settings-section-pressure",
          description: "The section frames one complete form and an optional typed status without owning fields, models, routes, or submission policy."
        ) do
          example("Minimal form", slug: "settings-section-minimal") do
            render_settings_section(
              id: "gallery-settings-section-minimal",
              title: "Workspace name",
              fields: [ [ :name, "Workspace name" ] ]
            )
          end

          example("Validation status", slug: "settings-section-validation") do
            render NitroKit::SettingsSection.new(
              title: "Profile",
              description: "Public details shown to workspace members.",
              id: "gallery-settings-section-validation"
            ) do |section|
              section.status NitroKit::Alert.new(variant: :destructive, id: "gallery-settings-section-validation-status") do |alert|
                alert.title("Profile was not saved")
                alert.description("Correct the highlighted name and email fields.")
              end
              section.form do
                form_with(url: "#profile", scope: :profile, builder: NitroKit::FormBuilder, id: "gallery-settings-section-validation-form") do |form|
                  form.group do
                    form.field(:name, label: "Display name", value: "", errors: [ "Display name can't be blank" ], required: true)
                    form.field(:email, as: :email, label: "Email", value: "not-an-email", errors: [ "Email is invalid" ], required: true)
                    form.submit("Save profile")
                  end
                end
              end
            end
          end

          example("Success status", slug: "settings-section-success") do
            render NitroKit::SettingsSection.new(
              title: "Notification settings",
              description: "Choose which operational changes should send email.",
              id: "gallery-settings-section-success"
            ) do |section|
              section.status NitroKit::Alert.new(variant: :success, id: "gallery-settings-section-success-status") do |alert|
                alert.title("Notification settings saved")
                alert.description("New incidents and weekly summaries will be delivered to ada@example.test.")
              end
              section.form do
                form_with(url: "#notifications", scope: :notifications, builder: NitroKit::FormBuilder, id: "gallery-settings-section-success-form") do |form|
                  form.group do
                    form.field(:incidents, as: :switch, label: "Incident alerts", checked: true)
                    form.field(:summaries, as: :switch, label: "Weekly summaries", checked: true)
                    form.submit("Save notifications")
                  end
                end
              end
            end
          end

          example("Dense long form", slug: "settings-section-dense", mode: :full_width, density: :compact) do
            render NitroKit::Container.new(size: :lg, id: "gallery-settings-section-dense-container") do
              render_settings_section(
                id: "gallery-settings-section-dense",
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

        example_section(
          "Under pressure",
          slug: "settings-section-stress",
          description: "An unbroken hundred-letter title, four paragraphs of description, a destructive status carrying the full slug error, and a form whose labels, values, help text, and errors all come from Gallery::Hostile."
        ) do
          example("Hostile form", slug: "settings-section-hostile", mode: :full_width, stress: true) do
            render NitroKit::SettingsSection.new(
              title: Gallery::Hostile::LONG_WORD,
              description: Gallery::Hostile::LONG_PARAGRAPH,
              id: "gallery-settings-section-hostile"
            ) do |section|
              section.status NitroKit::Alert.new(variant: :destructive, id: "gallery-settings-section-hostile-status") do |alert|
                alert.title(Gallery::Hostile::LONG_LABEL)
                alert.description("Workspace slug #{Gallery::Hostile::LONG_ERROR}.")
              end
              section.form do
                form_with(url: "#hostile", scope: :workspace, builder: NitroKit::FormBuilder, id: "gallery-settings-section-hostile-form") do |form|
                  form.group do
                    form.field(
                      :slug,
                      id: "gallery-settings-section-hostile-slug",
                      label: Gallery::Hostile::LONG_LABEL,
                      value: Gallery::Hostile::LONG_WORD,
                      errors: [ Gallery::Hostile::LONG_ERROR ],
                      required: true
                    )
                    form.field(
                      :billing_email,
                      as: :email,
                      id: "gallery-settings-section-hostile-email",
                      label: "Billing email",
                      value: Gallery::Hostile::LONG_EMAIL,
                      description: Gallery::Hostile::LONG_SENTENCE
                    )
                    form.field(
                      :owner,
                      id: "gallery-settings-section-hostile-owner",
                      label: Gallery::Hostile::RTL_NAME,
                      value: Gallery::Hostile::CJK_NAME
                    )
                    form.field(
                      :webhook_url,
                      as: :url,
                      id: "gallery-settings-section-hostile-webhook",
                      label: Gallery::Hostile::EMOJI_NAME,
                      value: Gallery::Hostile::LONG_URL
                    )
                    form.field(
                      :notes,
                      as: :textarea,
                      id: "gallery-settings-section-hostile-notes",
                      label: Gallery::Hostile::THAI_NAME,
                      value: Gallery::Hostile::LONG_PARAGRAPH
                    )
                    form.submit(Gallery::Hostile::ACTION_LABELS.fetch(1), id: "gallery-settings-section-hostile-submit")
                  end
                end
              end
            end
          end
        end
      end

      def render_settings_section(id:, title:, fields:, description: nil)
        render NitroKit::SettingsSection.new(title:, description:, id:) do |section|
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
