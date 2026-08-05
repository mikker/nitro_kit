module Gallery
  class DestructiveActionsController < ApplicationController
    def destroy
      redirect_to gallery_component_path("dialog"), status: :see_other
    end
  end
end
