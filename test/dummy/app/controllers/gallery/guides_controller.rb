module Gallery
  class GuidesController < ApplicationController
    def show
      render HumanGuide.new
    end
  end
end
