module Gallery
  class Page < Phlex::HTML
    PreviewDefinition = ::Data.define(:slug, :title, :mode, :layout, :density, :scroll, :stress, :content)

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

# Runs the page once with every example block skipped and returns the
# PreviewDefinitions it declared, so previews can be enumerated without a
# request. Gallery::Catalog.stress_previews and the stress lab use it.
def collect_previews
  @preview_definitions = []
  call
  @preview_definitions
ensure
  @preview_definitions = nil
end

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

    def render_account_menu(id:, placement: :top_start)
      render NitroKit::Dropdown.new(id:, placement:) do |menu|
        menu.trigger(icon_end: :chevrons_up_down) do
          span(data: { ui: "account-identity" }) do
            render NitroKit::Avatar.new(alt: "Ada Lovelace", size: :xs, decorative: true)
            span { "Ada Lovelace" }
          end
        end
        menu.item("Account", href: "#account", icon: :circle_user)
        menu.item("Settings", href: "#settings", icon: :settings)
        menu.separator
        menu.item("Sign out", icon: :log_out)
      end
    end

    def page_template
      raise NotImplementedError, "#{self.class.name} must implement #page_template"
    end

    # Outside a request (see #collect_previews) the page has no view context,
    # so links fall back to the application route helpers.
    def entry_path(entry, state: nil)
      routes = collecting_previews? ? Rails.application.routes.url_helpers : self
      Gallery::Catalog.path_for(entry, routes:, state:)
    end

    def render_example(
      slug:,
      title:,
      description: nil,
      mode: :constrained,
      layout: :stack,
      density: :comfortable,
      scroll: false,
      stress: false,
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
          stress:,
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
          stress:,
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
          scroll: definition.scroll,
          stress: definition.stress
        ),
        &definition.content
      )
    ensure
      @preview_definitions = nil
    end

    def collecting_previews?
      !@preview_definitions.nil?
    end

    def render_composition_header(eyebrow: nil, destinations: composition_destinations, navigation_label: nil)
      render NitroKit::PageHeader.new(
        title: entry.title,
        eyebrow:,
        description: entry.description,
        data: { gallery: "composition-header" }
      )

      return if destinations.empty?

      nav(
        aria: { label: navigation_label || "#{entry.title} states" },
        data: { gallery: "composition-states" }
      ) do
        render NitroKit::Flex.new(dir: :row, gap: 2, align: :center, wrap: :wrap) do
          destinations.each do |destination|
            render NitroKit::Button.new(
              destination.fetch(:label),
              href: destination.fetch(:href),
              size: :sm,
              variant: destination.fetch(:current) ? :primary : :ghost,
              aria: { current: destination.fetch(:current) ? "page" : nil }
            )
          end
        end
      end
    end

    def composition_destinations
      entry.states.map do |candidate|
        {
          label: humanize_state(candidate),
          href: entry_path(entry, state: candidate),
          current: candidate == state
        }
      end
    end

    def humanize_state(value)
      value.to_s.tr("-", " ").humanize
    end

    def normalize_example_slug(value)
      slug = value.to_s.tr("_", "-")
      return slug if slug.match?(Primitive::SLUG_PATTERN)

      raise ArgumentError, "Gallery example slug must contain only lowercase letters, numbers, and hyphens"
    end
  end
end
