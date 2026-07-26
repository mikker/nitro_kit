module Gallery
  module Blocks
    class PageHeaderPage < ComponentPage
      private

      def component_template
        example_section(
          "Content and action pressure",
          slug: "page-header-pressure",
          description: "Fixed h1 ordering from the smallest title through long copy and grouped actions."
        ) do
          example("Title only", slug: "page-header-title-only") do
            render NitroKit::PageHeader.new(title: "Audit log", id: "gallery-page-header-title-only")
          end

          example("Complete", slug: "page-header-complete") do
            render NitroKit::PageHeader.new(
              title: "Workspace members",
              eyebrow: "Administration",
              description: "Manage roles, invitations, and active access from one place.",
              id: "gallery-page-header-complete"
            ) do |header|
              header.actions NitroKit::ButtonGroup.new(label: "Member actions") do |actions|
                actions.button("Export", href: "#export")
                actions.button("Invite teammate", href: "#invite", variant: :primary)
              end
            end
          end

          example("Long copy", slug: "page-header-long", mode: :full_width) do
            render NitroKit::PageHeader.new(
              title: "International Research, Production, and Reliability Engineering workspace",
              eyebrow: "Long content pressure",
              description: "Review every access grant, invitation, service credential, and inherited project permission before the quarterly compliance export closes for all regional administrators.",
              id: "gallery-page-header-long"
            ) do |header|
              header.actions NitroKit::ButtonGroup.new(label: "Compliance actions") do |actions|
                actions.button("Download current report", href: "#download")
                actions.button("Start quarterly review", href: "#review", variant: :primary)
              end
            end
          end

          example(
            "Rich compound content",
            slug: "page-header-compound",
            description: "Eyebrow, title, and description accept deferred blocks; level: keeps a nested header out of the page h1."
          ) do
            render NitroKit::PageHeader.new(level: 2, id: "gallery-page-header-compound") do |header|
              header.eyebrow("Billing")
              header.title do
                plain "Invoices for "
                strong { "Analytical Engines" }
              end
              header.description do
                plain "Every invoice issued since "
                time(datetime: "2026-01-01") { "January 2026" }
                plain " remains downloadable."
              end
              header.actions NitroKit::ButtonGroup.new(label: "Invoice actions") do |actions|
                actions.button("Download all", href: "#download-invoices")
              end
            end
          end

          example("Nested in a narrow container", slug: "page-header-nested") do
            render NitroKit::Container.new(size: :sm, id: "gallery-page-header-container") do
              render NitroKit::PageHeader.new(
                title: "API credentials",
                description: "Rotate secrets without widening the page header API.",
                id: "gallery-page-header-nested"
              ) do |header|
                header.actions NitroKit::ButtonGroup.new(label: "Credential actions") do |actions|
                  actions.button("Create credential", href: "#create", variant: :primary)
                end
              end
            end
          end
        end
      end

      def source_note
        "NitroKit::PageHeader owns eyebrow → h1 → description → actions ordering and the narrow responsive collapse."
      end

      def api_note
        "Supply title, eyebrow, and description through constructor text or matching compound methods; title is required. level: picks the heading level 1..6 and actions accepts at most one NitroKit::ButtonGroup."
      end
    end
  end
end
