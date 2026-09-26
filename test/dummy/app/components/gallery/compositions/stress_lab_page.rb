module Gallery
  module Compositions
    # Every stress example in one screen. Each frame is the example's isolated
    # preview at phone width, which is where hostile content breaks first.
    # The list comes from Gallery::Catalog.stress_previews, the same
    # enumeration test/system/stress_sweep_test.rb audits.
    class StressLabPage < Page
      FRAME_WIDTH = 390

      private

      def page_template
        render_composition_header(destinations: [])

        render Section.new(
          slug: "stress-lab-screen",
          title: "Under pressure, all at once",
          description: "Phone-width previews of every example flagged stress: true. Scan for text that escapes, clips, or overlaps, then freeze what you find in Gallery::Hostile."
        ) do
          render_example(
            slug: "stress-lab-frames",
            title: "Every stress example",
            mode: :full_width,
            code: SourceCode.from_method(self.class.instance_method(:render_frames))
          ) { render_frames }
        end
      end

      def render_frames
        render NitroKit::Grid.new(cols: "1 md:2 xl:3", gap: 6, id: "gallery-stress-lab-grid") do
          Gallery::Catalog.stress_previews.each do |preview|
            render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch, data: { gallery: "stress-lab-item" }) do
              h3(data: { gallery: "stress-lab-title" }) do
                a(href: entry_path(preview.entry, state: preview.state)) { preview.entry.title }
                plain " · #{preview.title}"
              end
              iframe(
                src: preview_path(preview),
                title: "#{preview.entry.title}: #{preview.title} at #{FRAME_WIDTH}px",
                loading: "lazy",
                width: FRAME_WIDTH,
                data: { gallery: "stress-lab-frame" }
              )
            end
          end
        end
      end

      def preview_path(preview)
        Rails.application.routes.url_helpers.gallery_preview_path(
          kind: preview.entry.kind,
          slug: preview.entry.slug,
          example: preview.example,
          state: preview.state
        )
      end
    end
  end
end
