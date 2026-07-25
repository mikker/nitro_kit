module Gallery
  class BlocksController < ApplicationController
    def show
      render_catalog_entry(:block)
    end
  end
end
