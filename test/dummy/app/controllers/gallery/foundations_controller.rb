module Gallery
  class FoundationsController < ApplicationController
    def show
      render_catalog_entry(:foundation)
    end
  end
end
