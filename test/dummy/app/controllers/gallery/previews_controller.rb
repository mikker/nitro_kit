module Gallery
  class PreviewsController < ApplicationController
    layout -> { Gallery::PreviewLayout }

    def show
      entry = Gallery::Catalog.fetch!(kind: params[:kind], slug: params[:slug])
      state = Gallery::Catalog.resolve_state!(entry, params[:state])

      render entry.page.new(entry:, state:, preview: params[:example])
    rescue Gallery::Catalog::EntryNotFound,
      Gallery::Catalog::StateNotFound,
      Gallery::Page::PreviewNotFound
      head(:not_found)
    end
  end
end
