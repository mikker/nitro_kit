module Gallery
  module Components
    class FieldPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/field.rb"
      end

      def api_note
        "NitroKit::Field.new(form, name, label:, description:, errors:)"
      end

      def component_template
        example_section(
          "Control modes",
          slug: "field-controls",
          description: "One field contract composes labels and descriptions around native control types."
        ) do
          example(
            "Text controls",
            slug: "field-text-controls",
            mode: :full_width,
            layout: :matrix
          ) do
            sample("Text", slug: "text") do
              render NitroKit::Field.new(
                nil,
                :workspace_name,
                id: "gallery-field-text",
                value: "Mothership",
                label: "Workspace name",
                description: "Visible to everyone in the workspace.",
                required: true,
                html: { id: "gallery-field-text-wrapper" }
              )
            end
            sample("Textarea", slug: "textarea") do
              render NitroKit::Field.new(
                nil,
                :bio,
                as: :textarea,
                id: "gallery-field-textarea",
                value: "Building reliable interfaces for analytical software.",
                label: "Biography",
                html: { id: "gallery-field-textarea-wrapper" }
              )
            end
          end

          example(
            "Choice controls",
            slug: "field-choice-controls",
            mode: :full_width,
            layout: :matrix
          ) do
            sample("Select", slug: "select") do
              render NitroKit::Field.new(
                nil,
                :time_zone,
                as: :select,
                id: "gallery-field-select",
                value: "Europe/Copenhagen",
                label: "Time zone",
                prompt: "Choose a time zone",
                options: Gallery::Forms::Profile::TIME_ZONES,
                html: { id: "gallery-field-select-wrapper" }
              )
            end
            sample("Radio group", slug: "radio-group") do
              render NitroKit::Field.new(
                nil,
                :role,
                as: :radio_group,
                id: "gallery-field-radio-group",
                value: "member",
                label: "Default member role",
                options: [ [ "Administrator", "admin" ], [ "Member", "member" ], [ "Viewer", "viewer" ] ],
                html: { id: "gallery-field-radio-group-wrapper" }
              )
            end
          end

          example(
            "Boolean controls",
            slug: "field-boolean-controls",
            mode: :full_width,
            layout: :matrix
          ) do
            sample("Checkbox", slug: "checkbox") do
              render NitroKit::Field.new(
                nil,
                :weekly_digest,
                as: :checkbox,
                id: "gallery-field-checkbox",
                checked: true,
                label: "Send a weekly digest",
                description: "Includes deployments, invitations, and billing events.",
                html: { id: "gallery-field-checkbox-wrapper" }
              )
            end
            sample("Switch", slug: "switch") do
              render NitroKit::Field.new(
                nil,
                :deployment_alerts,
                as: :switch,
                id: "gallery-field-switch",
                checked: true,
                label: "Deployment alerts",
                description: "Notify the operations channel after every production deploy.",
                html: { id: "gallery-field-switch-wrapper" }
              )
            end
          end
        end

        example_section(
          "States",
          slug: "field-states",
          description: "Required, disabled, and invalid state is visible on the field and connected control."
        ) do
          example("Availability and validation", slug: "field-state-matrix", layout: :matrix) do
            sample("Required", slug: "required") do
              render NitroKit::Field.new(
                nil,
                :email,
                as: :email,
                id: "gallery-field-required",
                value: "ada@example.test",
                label: "Account email",
                required: true,
                html: { id: "gallery-field-required-wrapper" }
              )
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::Field.new(
                nil,
                :legacy_id,
                id: "gallery-field-disabled",
                value: "acct_legacy_42",
                label: "Legacy account ID",
                disabled: true,
                html: { id: "gallery-field-disabled-wrapper" }
              )
            end
            sample("Invalid", slug: "invalid") do
              invalid_profile = Gallery::FormExamples.profile(:invalid)
              render NitroKit::Field.new(
                nil,
                :email,
                as: :email,
                id: "gallery-field-invalid",
                value: invalid_profile.email,
                label: "Account email",
                description: "Used for security notices and account recovery.",
                errors: invalid_profile.errors.full_messages_for(:email),
                required: true,
                html: { id: "gallery-field-invalid-wrapper" }
              )
            end
          end
        end

        example_section(
          "Placement parents",
          slug: "field-placement-parents",
          description: "A Field owns its label, description, error, and one control, and nothing outside " \
            "itself. Everything between fields belongs to a parent. FieldGroup — `form.group` on the " \
            "builder — is the default vertical rhythm owner for bare fields and actions; two bare siblings " \
            "stack flush. Fieldset provides that rhythm for its direct field, group, and submit children " \
            "while adding native grouping: reach for it when a set of fields needs one shared accessible " \
            "name, and take the legend and description it brings with it. FormSection is also " \
            "optional and is the page-level region above the form: a titled header, an optional status " \
            "Alert, and exactly one form. Flex and Grid own placement when an arrangement is deliberately " \
            "inline or multi-column."
        ) do
          example(
            "Section, fieldset, and group together",
            slug: "field-placement-composition",
            mode: :full_width,
            description: "The section titles the region, the fieldset names the related address fields, " \
              "and each FieldGroup owns the gap between the controls it contains."
          ) do
            render NitroKit::FormSection.new(
              title: "Billing contact",
              description: "Invoices and receipts are sent to this contact.",
              id: "gallery-field-placement-section"
            ) do |section|
              section.form do
                billing = Gallery::FormExamples.billing_contact

                form_with(
                  model: billing,
                  scope: :billing_contact,
                  url: "#billing-contact",
                  builder: NitroKit::FormBuilder,
                  id: "gallery-field-placement-form"
                ) do |form|
                  form.group do
                    form.field(:company_name, id: "gallery-field-placement-company", label: "Company name", required: true)
                    form.field(:billing_email, as: :email, id: "gallery-field-placement-email", label: "Billing email")
                  end

                  render NitroKit::Fieldset.new(
                    legend: "Tax registration",
                    description: "Required for workspaces billed inside the EU.",
                    html: { id: "gallery-field-placement-fieldset" }
                  ) do
                    form.group do
                      form.field(
                        :country,
                        as: :select,
                        id: "gallery-field-placement-country",
                        label: "Country",
                        options: [ [ "Denmark", "DK" ], [ "Germany", "DE" ], [ "United States", "US" ] ]
                      )
                      form.field(:tax_id, id: "gallery-field-placement-tax-id", label: "Tax ID")
                    end
                  end

                  form.submit("Save billing contact", id: "gallery-field-placement-save")
                end
              end
            end
          end
        end

        example_section(
          "Long content",
          slug: "field-long-content",
          description: "Customer-provided labels and detailed guidance wrap without changing the component API."
        ) do
          example("Detailed configuration", slug: "field-detailed-configuration") do
            render NitroKit::Field.new(
              nil,
              :webhook_url,
              as: :url,
              id: "gallery-field-long-content",
              value: "https://integrations.example.test/nitro/events/production-workspace",
              label: "Production workspace webhook destination",
              description: "Nitro Kit sends deployment, access, and billing events to this HTTPS endpoint. " \
                "Changing it affects every administrator in the workspace.",
              required: true,
              html: { id: "gallery-field-long-content-wrapper" }
            )
          end
        end
      end
    end
  end
end
