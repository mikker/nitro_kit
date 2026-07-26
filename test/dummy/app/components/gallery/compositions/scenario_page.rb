module Gallery
  module Compositions
    class ScenarioPage < Page
      private

      def page_template
        header(data: { gallery: "composition-header" }) do
          p(data: { gallery: "eyebrow" }) { composition_label }
          h1 { entry.title }
          p { entry.description }
          state_navigation
        end

        render Section.new(
          slug: "#{entry.slug}-screen",
          title: section_title,
          description: section_description
        ) do
          render_example(
            slug: "#{entry.slug}-#{state}",
            title: state.to_s.humanize,
            description: state_description,
            mode: :full_width,
            code: SourceCode.from_method(self.class.instance_method(:render_scenario))
          ) do
            div(
              id: "gallery-#{entry.slug}-surface",
              aria: { busy: loading_state? ? "true" : nil },
              data: {
                gallery: "composition-surface",
                gallery_composition: entry.slug,
                gallery_composition_state: state,
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) { render_scenario }
          end
        end
      end

      def state_navigation
        nav(aria: { label: "#{entry.title} states" }, data: { gallery: "composition-states" }) do
          entry.states.each do |name|
            a(href: entry_path(entry, state: name), aria: { current: state == name ? "page" : nil }) do
              name.humanize
            end
          end
        end
      end

      def workspace_surface(size: :xl, &content)
        render NitroKit::Container.new(size:) do
          render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch), &content
        end
      end

      def loading_state?
        %w[loading processing saving retrying].include?(state)
      end

      def composition_label
        raise NotImplementedError
      end

      def section_title
        raise NotImplementedError
      end

      def section_description
        raise NotImplementedError
      end

      def state_description
        raise NotImplementedError
      end

      def render_scenario
        raise NotImplementedError
      end
    end
  end
end
