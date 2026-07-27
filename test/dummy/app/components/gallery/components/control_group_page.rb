module Gallery
  module Components
    class ControlGroupPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/control_group.rb"
      end

      def api_note
        "NitroKit::ControlGroup.new(label:) { |group| group.addon; render controls }"
      end

      def component_template
        example_section(
          "Joined controls",
          slug: "control-group-joined",
          description: "Input, Select, Button, and textual addons share one boundary while retaining native behavior."
        ) do
          example("Common constructions", slug: "control-group-constructions", layout: :stack) do
            sample("Copy field", slug: "copy-field") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-copy", label: "Copy webhook URL") do
                render NitroKit::Input.new(
                  value: "https://example.test/hooks/nk_live_7P3F",
                  readonly: true,
                  aria: { label: "Webhook URL" }
                )
                render NitroKit::Button.new("Copy", type: :button, icon: :copy)
              end
            end
            sample("URL builder", slug: "url-builder") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-url", label: "Workspace domain") do |group|
                group.addon("https://")
                render NitroKit::Input.new(
                  name: "workspace[subdomain]",
                  value: "orbital",
                  aria: { label: "Workspace subdomain" }
                )
                group.addon(".example.test")
              end
            end
            sample("Filter and submit", slug: "filter-submit") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-filter", label: "Filter activity") do
                render NitroKit::Select.new(
                  name: "filter[period]",
                  value: "week",
                  control_aria: { label: "Activity period" },
                  options: [ [ "This week", "week" ], [ "This month", "month" ] ]
                )
                render NitroKit::Button.new("Apply", type: :submit)
              end
            end
          end
        end
      end
    end
  end
end
