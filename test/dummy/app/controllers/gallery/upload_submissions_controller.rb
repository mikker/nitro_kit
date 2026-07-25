module Gallery
  class UploadSubmissionsController < ApplicationController
    def create
      files = Array(params.dig(:upload, :files)).compact
      names = files.map { |file| file.respond_to?(:original_filename) ? file.original_filename : "direct upload" }

      render plain: "Received #{files.size} #{"file".pluralize(files.size)}: #{names.join(", ")}"
    end
  end
end
