module Gallery
  class Page < Phlex::HTML
    PreviewDefinition = ::Data.define(:slug, :title, :mode, :layout, :density, :scroll, :content)

    class PreviewNotFound < KeyError
    end

    class DuplicatePreview < KeyError
    end

    include Phlex::Rails::Helpers::Routes

    def initialize(entry:, state: nil, preview: nil)
      @entry = entry
      @state = state
      @preview = preview&.to_s
    end

    attr_reader :entry, :state, :preview

    def view_template
      if preview
        preview_template
      else
        div(
          data: {
            gallery: "page",
            gallery_page: entry.slug,
            gallery_state: state
          }.compact
        ) do
          page_template
        end
      end
    end

    private

    def page_template
      raise NotImplementedError, "#{self.class.name} must implement #page_template"
    end

    def entry_path(entry, state: nil)
      Gallery::Catalog.path_for(entry, routes: self, state:)
    end

    def render_example(
      slug:,
      title:,
      description: nil,
      mode: :constrained,
      layout: :stack,
      density: :comfortable,
      scroll: false,
      source: nil,
      api: nil,
      code: nil,
      &block
    )
      raise ArgumentError, "Gallery examples require a preview block" unless block

      if collecting_previews?
        @preview_definitions << PreviewDefinition.new(
          slug: normalize_example_slug(slug),
          title:,
          mode:,
          layout:,
          density:,
          scroll:,
          content: block
        )
        return
      end

      code ||= SourceCode.from_block(block)

      render(
        Example.new(
          slug:,
          title:,
          description:,
          mode:,
          layout:,
          density:,
          scroll:,
          source:,
          api:,
          code:,
          preview_path: Rails.application.routes.url_helpers.gallery_preview_path(
            kind: entry.kind,
            slug: entry.slug,
            example: normalize_example_slug(slug),
            state:
          )
        ),
        &block
      )
    end

    def preview_template
      @preview_definitions = []
      capture { page_template }

      matches = @preview_definitions.select { |definition| definition.slug == preview }
      if matches.empty?
        raise PreviewNotFound, "Unknown preview #{preview.inspect} for #{entry.slug.inspect}"
      end
      if matches.many?
        raise DuplicatePreview, "Duplicate preview #{preview.inspect} for #{entry.slug.inspect}"
      end

      definition = matches.first
      render(
        ExamplePreview.new(
          slug: definition.slug,
          title: definition.title,
          mode: definition.mode,
          layout: definition.layout,
          density: definition.density,
          scroll: definition.scroll
        ),
        &definition.content
      )
    ensure
      @preview_definitions = nil
    end

    def collecting_previews?
      !@preview_definitions.nil?
    end

    def normalize_example_slug(value)
      slug = value.to_s.tr("_", "-")
      return slug if slug.match?(Primitive::SLUG_PATTERN)

      raise ArgumentError, "Gallery example slug must contain only lowercase letters, numbers, and hyphens"
    end
  end
end
