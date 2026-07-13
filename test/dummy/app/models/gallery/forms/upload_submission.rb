module Gallery
  module Forms
    class UploadSubmission
      include ActiveModel::Model
      include ActiveModel::Attributes

      DESTINATIONS = %w[customer_accounts deployment_events research_archive].freeze

      attr_accessor :files

      attribute :destination, :string
      attribute :note, :string
      attribute :overwrite, :boolean, default: false

      validates :destination, inclusion: { in: DESTINATIONS }
      validates :note, length: { maximum: 240 }
      validate :files_are_present
      validate :file_count_is_supported

      private

      def files_are_present
        errors.add(:files, "must include at least one file") if Array(files).empty?
      end

      def file_count_is_supported
        errors.add(:files, "cannot include more than five files") if Array(files).size > 5
      end
    end
  end
end
