module Gallery
  module Compositions
    class ApplicationPage < Page
      include Phlex::Rails::Helpers::FormWith

      APPLICATION_SLUGS = %w[application-sidebar application-topbar application-hybrid].freeze

      class DemoBlob
        def metadata = { "width" => 1_200, "height" => 800 }
        def analyzed? = true
        def image? = true
        def variable? = true
      end

      class DemoAttachment
        def initialize(path: "/gallery/progressive-workspace.svg")
          @path = path
        end

        def attached? = true
        def blob = DemoBlob.new
        def filename = "workspace-illustration.svg"

        def variant(resize_to_limit:)
          width, height = resize_to_limit
          "#{@path}?variant=#{width}x#{height}"
        end
      end

      private

      def page_template
        render_composition_header(
          destinations: application_destinations,
          navigation_label: "Complete application layouts"
        )

        application_template
      end

      def application_template
        raise NotImplementedError, "#{self.class.name} must implement #application_template"
      end

      def application_destinations
        APPLICATION_SLUGS.map do |slug|
          target = Gallery::Catalog.fetch!(kind: :composition, slug:)
          {
            label: target.title,
            href: entry_path(target),
            current: entry.slug == slug
          }
        end
      end

      def application_section(title, slug:, description:, &block)
        render Section.new(slug:, title:, description:), &block
      end

      def application_example(title, slug:, description:, source:, &block)
        render_example(
          slug:,
          title:,
          description:,
          mode: :full_width,
          source: self.class.name,
          code: SourceCode.from_method(self.class.instance_method(source)),
          &block
        )
      end

      def render_application_navigation(
        id:,
        current:,
        context:,
        dense: false,
        compact: false,
        appearance_picker_id: nil
      )
        render NitroKit::AppNavigation.new(id:, label: "#{context} navigation") do |navigation|
          navigation.body do
            if compact
              navigation.item("Overview", href: "#overview", icon: :house, current: current == :overview)
              navigation.item("Projects", href: "#projects", icon: :folder, badge: 12, current: current == :projects)
              navigation.item("People", href: "#people", icon: :users, current: current == :people)
              navigation.item("Settings", href: "#settings", icon: :settings, current: current == :settings)
            else
              navigation.section(label: "Workspace") do
                navigation.item("Overview", href: "#overview", icon: :house, current: current == :overview)
                navigation.item("Projects", href: "#projects", icon: :folder, badge: 12, current: current == :projects)
                navigation.item("People", href: "#people", icon: :users, current: current == :people)
              end
              navigation.section(label: "Operate") do
                navigation.item("Deployments", href: "#deployments", icon: :rocket, current: current == :deployments)
                navigation.item("Incidents", href: "#incidents", icon: :siren, badge: dense ? 8 : 2, current: current == :incidents)
                navigation.item("Audit log", href: "#audit-log", icon: :scroll_text, current: current == :audit)
              end
              navigation.spacer
              navigation.item("Settings", href: "#settings", icon: :settings, current: current == :settings)
            end
          end
          unless compact
            navigation.footer do
              render NitroKit::Flex.new(dir: :row, gap: 2, align: :center, justify: :between) do
                render NitroKit::Button.new("Help", href: "#help", size: :sm, icon: :circle_help)
                if appearance_picker_id
                  appearance_picker(
                    appearance_picker_id,
                    label: "Navigation appearance",
                    presentation: :dropdown
                  )
                end
              end
            end
          end
        end
      end

      def render_application_main(size: :xl, &content)
        div(data: { gallery: "app-shell-main" }) do
          render NitroKit::Container.new(size:) do
            render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch), &content
          end
        end
      end

      def demo_attachment
        DemoAttachment.new
      end

      def appearance_picker(id, label: "Appearance", presentation: :segmented)
        render NitroKit::AppearancePicker.new(id:, label:, presentation:)
      end

      def status_badge(status, id: nil)
        color = {
          healthy: :success,
          active: :success,
          queued: :info,
          waiting: :warning,
          failed: :danger,
          missing: :neutral
        }.fetch(status)

        render NitroKit::Badge.new(status.to_s.humanize, id:, color:, size: :sm)
      end
    end
  end
end
