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
            sample("Copy field (static preview; the application wires the copy behavior)", slug: "copy-field") do
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
            sample("Currency prefix and suffix", slug: "currency") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-currency", label: "Invoice amount") do |group|
                group.addon("$", html: { id: "gallery-currency-symbol" })
                render NitroKit::Input.new(
                  type: :number,
                  id: "gallery-currency-input",
                  name: "invoice[amount]",
                  value: "125.00",
                  min: 0,
                  step: "0.01",
                  aria: {
                    label: "Invoice amount",
                    describedby: "gallery-currency-symbol gallery-currency-code"
                  }
                )
                group.addon("USD", html: { id: "gallery-currency-code" })
              end
            end
            sample("Measurement units", slug: "units") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-units", label: "Package weight") do |group|
                render NitroKit::Input.new(
                  type: :number,
                  id: "gallery-weight-input",
                  name: "package[weight]",
                  value: "12.5",
                  min: 0,
                  step: "0.1",
                  aria: { label: "Package weight", describedby: "gallery-weight-unit" }
                )
                group.addon("kg", html: { id: "gallery-weight-unit" })
              end
            end
            sample("Phone country selector", slug: "phone-country") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-phone", label: "Phone number") do
                render NitroKit::Select.new(
                  name: "contact[country_code]",
                  value: "+1",
                  control_aria: { label: "Country code" },
                  options: [ [ "US +1", "+1" ], [ "DK +45", "+45" ], [ "GB +44", "+44" ] ]
                )
                render NitroKit::Input.new(
                  type: :tel,
                  name: "contact[phone]",
                  placeholder: "555 012 3456",
                  aria: { label: "Phone number" }
                )
              end
            end
            sample("Intrinsic button heights", slug: "intrinsic-button-heights") do
              render NitroKit::Flex.new(dir: :col, gap: 3) do
                render NitroKit::ControlGroup.new(id: "gallery-control-group-size-sm", label: "Small action") do
                  render NitroKit::Input.new(
                    value: "Shared 40 px height",
                    aria: { label: "Small action value" }
                  )
                  render NitroKit::Button.new("Save", size: :sm)
                end
                render NitroKit::ControlGroup.new(id: "gallery-control-group-size-lg", label: "Large action") do |group|
                  render NitroKit::Select.new(
                    value: "week",
                    control_aria: {
                      label: "Large action period",
                      describedby: "gallery-control-group-size-lg-addon"
                    },
                    options: [ [ "This week", "week" ], [ "This month", "month" ] ]
                  )
                  group.addon("UTC", html: { id: "gallery-control-group-size-lg-addon" })
                  render NitroKit::Button.new("Run", size: :lg)
                end
                render NitroKit::ControlGroup.new(id: "gallery-control-group-date", label: "Date action") do |group|
                  group.addon("Date", html: { id: "gallery-control-group-date-addon" })
                  render NitroKit::Input.new(
                    type: :date,
                    value: "2026-07-30",
                    aria: {
                      label: "Action date",
                      describedby: "gallery-control-group-date-addon"
                    }
                  )
                  render NitroKit::Button.new("Rotate")
                end
              end
            end
            sample("Disabled members", slug: "disabled") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-disabled", label: "Rotate API key") do
                render NitroKit::Input.new(
                  value: "nk_live_7P3F",
                  disabled: true,
                  aria: { label: "API key" }
                )
                render NitroKit::Button.new("Rotate", disabled: true)
              end
            end
            sample("Invalid member", slug: "invalid") do
              render NitroKit::ControlGroup.new(id: "gallery-control-group-invalid", label: "Workspace domain") do |group|
                group.addon("https://")
                render NitroKit::Input.new(
                  name: "workspace[subdomain]",
                  value: "or bital",
                  aria: { label: "Workspace subdomain", invalid: true }
                )
                group.addon(".example.test")
              end
            end
            sample("Narrow container", slug: "narrow") do
              render NitroKit::Container.new(size: :sm, id: "gallery-control-group-narrow-container") do
                render NitroKit::ControlGroup.new(id: "gallery-control-group-narrow", label: "Filter activity") do
                  render NitroKit::Select.new(
                    name: "narrow_filter[period]",
                    value: "week",
                    control_aria: { label: "Activity period" },
                    options: [ [ "This week", "week" ], [ "This month", "month" ] ]
                  )
                  render NitroKit::Input.new(
                    name: "narrow_filter[query]",
                    placeholder: "Search events",
                    aria: { label: "Search events" }
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
end
