module Gallery
  class ButtonSubmissionsController < ApplicationController
    def create
      sleep 2
      redirect_to gallery_component_path("button"), status: :see_other
    end
  end
end
