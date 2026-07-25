module Gallery
  module Forms
    class EmailVerification
      include ActiveModel::Model
      include ActiveModel::Attributes

      TOKEN_STATUSES = %w[valid expired invalid].freeze

      attribute :token, :string
      attribute :token_status, :string, default: "valid"

      validates :token, presence: true
      validates :token_status, inclusion: { in: TOKEN_STATUSES }
      validate :token_must_be_usable

      private

      def token_must_be_usable
        errors.add(:token, token_status == "expired" ? "has expired" : "is invalid") unless token_status == "valid"
      end
    end
  end
end
