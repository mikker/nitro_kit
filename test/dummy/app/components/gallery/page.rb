module Gallery
  class Page < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    def initialize(entry:, state: nil)
      @entry = entry
      @state = state
    end

    attr_reader :entry, :state

    def view_template
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
          code:
        ),
        &block
      )
    end
  end
end
