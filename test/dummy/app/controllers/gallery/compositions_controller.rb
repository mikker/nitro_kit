module Gallery
  class CompositionsController < ApplicationController
    def show
      render_catalog_entry(:composition)
    end
  end
end
