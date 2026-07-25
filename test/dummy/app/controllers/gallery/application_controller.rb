module Gallery
  class ApplicationController < ::ApplicationController
    layout -> { Gallery::Layout }

    private

    def render_catalog_entry(kind, slug: params[:slug], state: params[:state])
      entry = Gallery::Catalog.fetch!(kind:, slug:)
      state = Gallery::Catalog.resolve_state!(entry, state)

      render(entry.page.new(entry:, state:))
    rescue Gallery::Catalog::EntryNotFound, Gallery::Catalog::StateNotFound
      head(:not_found)
    end
  end
end
