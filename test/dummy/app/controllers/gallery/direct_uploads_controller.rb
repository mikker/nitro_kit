module Gallery
  class DirectUploadsController < ActiveStorage::DirectUploadsController
    MAX_BYTES = 10.megabytes
    MAX_PENDING = 12

    rate_limit to: 30, within: 1.minute

    def create
      attributes = blob_args.except(:metadata)
      attributes[:byte_size] = Integer(attributes[:byte_size], exception: false)
      unless attributes[:byte_size]&.between?(1, MAX_BYTES) &&
          attributes[:filename].to_s.bytesize.between?(1, 255) &&
          attributes[:content_type].to_s.bytesize <= 255 &&
          attributes[:checksum].to_s.match?(/\A[A-Za-z0-9+\/]{22}==\z/)
        return head :unprocessable_entity
      end

      owner = session[:gallery_upload_owner] ||= SecureRandom.hex(32)
      pending = ActiveStorage::Blob.where("metadata LIKE ?", "%#{owner}%").where(created_at: 30.minutes.ago..)
      return head :too_many_requests if pending.count >= MAX_PENDING

      blob = ActiveStorage::Blob.create_before_direct_upload!(**attributes,
        metadata: { gallery_upload_owner: owner })
      render json: direct_upload_json(blob)
    end
  end
end
