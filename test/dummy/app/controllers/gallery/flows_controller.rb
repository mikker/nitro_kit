module Gallery
  class FlowsController < ApplicationController
    def show
      render_catalog_entry(:flow)
    end
  end
end
