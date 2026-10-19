module Gallery
  class ComboboxReleasesController < ApplicationController
    def create
      release = ComboboxRelease.new(params.require(:release).permit(:title, label_ids: []))

      if release.valid?
        render ComboboxReleaseForm.new(release: ComboboxRelease.new, saved: release), layout: false
      else
        render ComboboxReleaseForm.new(release:), status: :unprocessable_entity, layout: false
      end
    end
  end
end
