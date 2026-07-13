module Gallery
  class ComponentsController < ApplicationController
    def show
      render_catalog_entry(:component)
    end
  end
end
