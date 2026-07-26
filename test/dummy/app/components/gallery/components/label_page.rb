module Gallery
  module Components
    class LabelPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/label.rb"
      end

      def api_note
        "NitroKit::Label.new(text, for:, id:)"
      end

      def component_template
        example_section(
          "Native relationships",
          slug: "label-relationships",
          description: "Labels point at ordinary native controls without taking ownership of those controls."
        ) do
          example("Control labels", slug: "label-control-labels", layout: :matrix) do
            sample("Input", slug: "input") do
              render NitroKit::Label.new(
                "Billing email",
                for: "gallery-label-email",
                id: "gallery-label-email-label"
              )
              render NitroKit::Input.new(
                type: :email,
                id: "gallery-label-email",
                name: "billing[email]",
                value: "billing@example.test",
                required: true
              )
            end
            sample("Textarea", slug: "textarea") do
              render NitroKit::Label.new(
                "Invitation message",
                for: "gallery-label-message",
                id: "gallery-label-message-label"
              )
              render NitroKit::Textarea.new(
                id: "gallery-label-message",
                name: "invitation[message]",
                value: "Join the release planning workspace."
              )
            end
            sample("Select", slug: "select") do
              render NitroKit::Label.new(
                "Workspace role",
                for: "gallery-label-role",
                id: "gallery-label-role-label"
              )
              render NitroKit::Select.new(
                id: "gallery-label-role",
                name: "member[role]",
                value: "member",
                options: [ [ "Administrator", "admin" ], [ "Member", "member" ] ]
              )
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "label-content",
          description: "Plain text and block content support concise product labels and unusually long customer copy."
        ) do
          example("Text and block content", slug: "label-text-block", layout: :matrix) do
            sample("Block content", slug: "block") do
              render NitroKit::Label.new(for: "gallery-label-search", id: "gallery-label-search-label") do
                strong { "Search" }
                plain(" workspace members")
              end
              render NitroKit::Input.new(
                type: :search,
                id: "gallery-label-search",
                name: "members[query]",
                placeholder: "Name or email"
              )
            end
            sample("Long label", slug: "long") do
              render NitroKit::Label.new(
                "Describe the production incident and include the customer-visible impact, affected regions, and recovery timeline",
                for: "gallery-label-incident",
                id: "gallery-label-incident-label"
              )
              render NitroKit::Textarea.new(
                id: "gallery-label-incident",
                name: "incident[summary]",
                value: ""
              )
            end
          end
        end

        example_section(
          "Rails field composition",
          slug: "label-rails",
          description: "The Nitro form builder derives label text and native for/id relationships from the model field."
        ) do
          example("Profile labels", slug: "label-profile-form") do
            profile = Gallery::FormExamples.profile

            form_with(
              model: profile,
              scope: :profile,
              url: "#profile-labels",
              builder: NitroKit::FormBuilder,
              id: "gallery-label-profile-form"
            ) do |form|
              form.group do
                form.field(:name, id: "gallery-label-profile-name", required: true)
                form.field(
                  :email,
                  as: :email,
                  id: "gallery-label-profile-email",
                  label: "Account email",
                  description: "Used for recovery and security notices."
                )
              end
            end
          end
        end
      end
    end
  end
end
