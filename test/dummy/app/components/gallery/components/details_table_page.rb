module Gallery
  module Components
    class DetailsTablePage < ComponentPage
      Profile = ::Data.define(
        :name,
        :nickname,
        :email,
        :active,
        :joined_on,
        :score,
        :website,
        :roles,
        :status
      )

      PROFILE = Profile.new(
        name: "Ada Lovelace",
        nickname: nil,
        email: "ada@example.test",
        active: true,
        joined_on: Date.new(2024, 2, 12),
        score: 98.6,
        website: "https://example.test/ada",
        roles: [ "Workspace owner", "Billing administrator" ].freeze,
        status: :active
      )

      private

      def source_note
        "app/components/nitro_kit/details_table.rb"
      end

      def api_note
        "NitroKit::DetailsTable.new(record) { |details| details.field(:name); details.fields(:email, :role) }"
      end

      def component_template
        example_section(
          "Resolved fields",
          slug: "details-table-resolved",
          description: "Attributes resolve through public Ruby methods; labels and Rails-friendly value formatting remain deterministic."
        ) do
          example("Member profile", slug: "details-table-member-profile", mode: :full_width) do
            render NitroKit::DetailsTable.new(PROFILE, id: "gallery-details-table-profile") do |details|
              details.fields(:name, :email, :active, :joined_on, :score, :website, :roles)
            end
          end
        end

        example_section(
          "Omitted and explicit values",
          slug: "details-table-values",
          description: "An omitted value reads the record. An explicit nil remains nil, and a field block receives that resolved value."
        ) do
          example("Nil and overrides", slug: "details-table-nil-and-overrides", mode: :full_width) do
            render NitroKit::DetailsTable.new(PROFILE, id: "gallery-details-table-values") do |details|
              details.field(:nickname)
              details.field(:nickname, label: "Public nickname", value: nil) do |value|
                value.nil? ? "Intentionally not published" : value
              end
              details.field(:score, label: "Quality score", value: "98.6 / 100")
            end
          end
        end

        example_section(
          "Application rendering",
          slug: "details-table-custom",
          description: "Blocks own application-specific presentation while the table retains its record structure."
        ) do
          example("Status and actions", slug: "details-table-status", mode: :full_width) do
            render NitroKit::DetailsTable.new(PROFILE, id: "gallery-details-table-custom") do |details|
              details.field(:name, label: "Account") do |name|
                strong { name }
              end
              details.field(:status) do |status|
                render NitroKit::Badge.new(
                  status.to_s.humanize,
                  id: "gallery-details-table-status-badge",
                  color: :success,
                  size: :sm
                )
              end
              details.field(:email, label: "Contact") do |email|
                a(href: "mailto:#{email}") { email }
              end
            end
          end
        end

        example_section(
          "Compositions",
          slug: "details-table-compositions",
          description: "Details and progressive media can form one classless application-owned record surface."
        ) do
          example("Workspace record card", slug: "details-table-record-card", mode: :full_width) do
            render NitroKit::Card.new(id: "gallery-details-table-card") do |card|
              card.title("Workspace owner", level: 3)
              card.full_width do
                render NitroKit::ProgressiveImage.new(
                  attachment: demo_attachment,
                  alt: "Abstract indigo workspace illustration",
                  size: :sm,
                  id: "gallery-details-table-image"
                )
              end
              card.body do
                render NitroKit::DetailsTable.new(PROFILE, id: "gallery-details-table-card-values") do |details|
                  details.fields(:name, :email, :joined_on)
                end
              end
            end
          end
        end
      end

      def demo_attachment
        ProgressiveImagePage::DemoAttachment.new(path: "/gallery/progressive-workspace.svg")
      end
    end
  end
end
