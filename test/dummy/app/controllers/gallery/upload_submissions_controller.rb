module Gallery
  class UploadSubmissionsController < ApplicationController
    def create
      mode = params.fetch(:mode, "multipart")
      raise ActionController::BadRequest unless UploadPreview::MODES.include?(mode)

      upload = params.fetch(:upload, {})
      files = if mode == "shared"
        [ upload[:primary_file], upload[:secondary_file] ]
      else
        Array(upload[:files])
      end.compact_blank
      if files.empty? || files.size > 3
        message = files.empty? ? "Choose at least one file." : "Choose no more than three files."
        return render UploadPreview.new(mode:, error: message), status: :unprocessable_entity, layout: false
      end

      # This throwaway demo reads the real uploaded data and releases its blobs.
      # An application would attach or import the files at this boundary.
      blobs = []
      receipt = files.map do |file|
        if file.is_a?(ActionDispatch::Http::UploadedFile)
          { name: file.original_filename, bytes: file.size }
        else
          blob = ActiveStorage::Blob.find_signed!(file)
          blobs << blob
          blob.open { |io| { name: blob.filename.to_s, bytes: io.size } }
        end
      end
      blobs.each(&:purge)

      render UploadPreview.new(mode:, receipt:), layout: false
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound,
        ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError
      render UploadPreview.new(mode:, error: "That upload is no longer available. Choose the file again."),
        status: :unprocessable_entity, layout: false
    end
  end
end
