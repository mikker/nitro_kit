module Gallery
  module Flows
    class ExpandedPage < Page
      include Phlex::Rails::Helpers::FormWith

      private

      def page_template
        header(data: { gallery: "flow-header" }) do
          h1 { entry.title }
          p { entry.description }
          state_navigation
        end

        render Section.new(
          slug: "#{entry.slug}-screen",
          title: entry.title,
          description: "Block-composed #{entry.group.downcase} coverage across realistic application states."
        ) do
          render_example(
            slug: "#{entry.slug}-#{state}",
            title: state.humanize,
            description: state_description,
            mode: :full_width,
            density: state == "dense" ? :compact : :comfortable,
            code: SourceCode.from_method(self.class.instance_method(:render_state))
          ) do
            div(
              id: "gallery-#{entry.slug}-surface",
              data: {
                gallery: "flow-surface",
                gallery_flow: entry.slug,
                gallery_flow_state: state,
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-#{entry.slug}-container") do
                render NitroKit::VStack.new(
                  gap: :lg,
                  align: :stretch,
                  id: "gallery-#{entry.slug}-stack"
                ) do
                  render_page_header
                  render_state
                end
              end
            end
          end
        end
      end

      def render_page_header
        render NitroKit::PageHeader.new(
          title: screen_title,
          description: state_description,
          id: "gallery-#{entry.slug}-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(
              id: "gallery-#{entry.slug}-header-actions",
              label: "#{entry.title} actions"
            )
          ) { |actions| header_actions(actions) }
        end
      end

      def state_navigation
        nav(aria: { label: "#{entry.title} states" }) do
          render NitroKit::ButtonGroup.new(label: "#{entry.title} states") do |group|
            entry.states.each do |candidate|
              group.button(
                candidate.humanize,
                href: flow_path(state: candidate),
                size: :sm,
                variant: candidate == state ? :primary : :ghost,
                aria: { current: candidate == state ? "page" : nil }
              )
            end
          end
        end
      end

      def flow_path(state:, **query)
        gallery_flow_path(**{ slug: entry.slug, state:, **query }.compact)
      end

      def screen_title
        entry.title
      end

      def outcome_color(outcome)
        {
          success: :success,
          pending: :info,
          warning: :warning,
          blocked: :danger
        }.fetch(outcome, :neutral)
      end

      def resource_status_color(status)
        {
          healthy: :success,
          degraded: :warning,
          syncing: :info,
          read_only: :neutral
        }.fetch(status, :neutral)
      end

      def render_state
        raise NotImplementedError, "#{self.class.name} must implement #render_state"
      end

      def header_actions(_actions)
        raise NotImplementedError, "#{self.class.name} must implement #header_actions"
      end

      def state_description
        raise NotImplementedError, "#{self.class.name} must implement #state_description"
      end
    end
  end
end
