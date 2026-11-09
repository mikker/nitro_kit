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

      receipt = ActiveStorage::Blob.transaction do
        signed_files = files.reject { _1.is_a?(ActionDispatch::Http::UploadedFile) }
          .to_h { [ _1, ActiveStorage::Blob.find_signed!(_1) ] }
        blobs = signed_files.values.uniq(&:id).sort_by(&:id)
        blobs.each do |blob|
          blob.lock!
          unless session[:gallery_upload_owner].present? &&
              blob.metadata["gallery_upload_owner"] == session[:gallery_upload_owner] &&
              blob.created_at > 30.minutes.ago && !blob.attachments.exists? &&
              blob.byte_size.between?(1, DirectUploadsController::MAX_BYTES)
            raise ActiveRecord::RecordNotFound
          end
        end
        # Validate the entire set before opening or purging any blob.
        result = files.map do |file|
          if file.is_a?(ActionDispatch::Http::UploadedFile)
            raise ActionController::BadRequest if file.size > DirectUploadsController::MAX_BYTES
            { name: file.original_filename, bytes: file.size }
          else
            blob = signed_files.fetch(file)
            blob.open { |io| { name: blob.filename.to_s, bytes: io.size } }
          end
        end
        blobs.each(&:purge)
        result
      end

      render UploadPreview.new(mode:, receipt:), layout: false
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound,
        ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError
      render UploadPreview.new(mode:, error: "That upload is no longer available. Choose the file again."),
        status: :unprocessable_entity, layout: false
    end
  end
end
