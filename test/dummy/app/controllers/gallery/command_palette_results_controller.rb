module Gallery
  class CommandPaletteResultsController < ApplicationController
    def index
      render CommandPaletteResults.new(query: params[:query]), layout: false
    end
  end
end
