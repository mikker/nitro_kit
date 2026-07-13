module Gallery
  module Forms
    class InvitationAcceptance
      include ActiveModel::Model
      include ActiveModel::Attributes

      TOKEN_STATUSES = %w[valid expired invalid].freeze

      attribute :token, :string
      attribute :token_status, :string, default: "valid"
      attribute :name, :string
      attribute :password, :string
      attribute :terms, :boolean, default: false

      validates :token, presence: true
      validates :token_status, inclusion: { in: TOKEN_STATUSES }
      validates :name, presence: true, length: { maximum: 80 }
      validates :password, presence: true, length: { minimum: 12 }
      validates :terms, acceptance: true
      validate :token_must_be_usable

      private

      def token_must_be_usable
        errors.add(:token, token_status == "expired" ? "has expired" : "is invalid") unless token_status == "valid"
      end
    end
  end
end
