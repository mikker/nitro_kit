module Gallery
  class HomeController < ApplicationController
    def show
      entry = Gallery::Catalog.home

      render(entry.page.new(entry:))
    end
  end
end
