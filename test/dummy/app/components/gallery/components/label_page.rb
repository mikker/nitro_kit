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
          description: "Labels point at ordinary native controls without taking ownership of those controls. " \
            "A label is a native inline element and owns no placement of its own, so the parent stacks it " \
            "above its control — here Flex, and inside Field the field grid."
        ) do
          example("Control labels", slug: "label-control-labels", layout: :matrix) do
            sample("Input", slug: "input") do
              render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
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
            end
            sample("Textarea", slug: "textarea") do
              render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
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
            end
            sample("Select", slug: "select") do
              render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
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
        end

        example_section(
          "Content pressure",
          slug: "label-content",
          description: "Plain text and block content support concise product labels and unusually long customer copy."
        ) do
          example("Text and block content", slug: "label-text-block", layout: :matrix) do
            sample("Block content", slug: "block") do
              render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
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
            end
            sample("Long label", slug: "long") do
              render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
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

        example_section(
          "Under pressure",
          slug: "label-stress",
          description: "Every hostile identity from Gallery::Hostile plus an unbroken word and a full paragraph as label text " \
            "above a control carrying the matching value."
        ) do
          example("Hostile label text", slug: "label-hostile", stress: true, layout: :matrix) do
            texts = {
              "word" => Gallery::Hostile::LONG_WORD,
              "paragraph" => Gallery::Hostile::LONG_PARAGRAPH,
              "url" => Gallery::Hostile::LONG_URL,
              "rtl" => Gallery::Hostile::RTL_NAME,
              "cjk" => Gallery::Hostile::CJK_NAME,
              "thai" => Gallery::Hostile::THAI_NAME,
              "emoji" => Gallery::Hostile::EMOJI_NAME,
              "zero-width" => Gallery::Hostile::ZERO_WIDTH_NAME,
              "combining" => Gallery::Hostile::COMBINING_NAME
            }

            texts.each do |slug, text|
              sample(slug.humanize, slug:) do
                render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
                  render NitroKit::Label.new(
                    text,
                    for: "gallery-label-hostile-#{slug}",
                    id: "gallery-label-hostile-#{slug}-label"
                  )
                  render NitroKit::Input.new(
                    id: "gallery-label-hostile-#{slug}",
                    name: "hostile[#{slug.tr("-", "_")}]",
                    value: text
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
