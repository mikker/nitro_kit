module Gallery
  module Forms
    class PasswordReset
      include ActiveModel::Model
      include ActiveModel::Attributes

      STAGES = %w[request update].freeze
      TOKEN_STATUSES = %w[valid expired invalid].freeze

      attribute :stage, :string, default: "request"
      attribute :email, :string
      attribute :token, :string
      attribute :token_status, :string, default: "valid"
      attribute :password, :string
      attribute :password_confirmation, :string

      validates :stage, inclusion: { in: STAGES }
      validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :request?
      validates :token, presence: true, if: :update?
      validates :token_status, inclusion: { in: TOKEN_STATUSES }, if: :update?
      validates :password, presence: true, length: { minimum: 12 }, confirmation: true, if: :update?
      validates :password_confirmation, presence: true, if: :update?
      validate :token_must_be_usable, if: :update?

      def request? = stage == "request"
      def update? = stage == "update"

      private

      def token_must_be_usable
        errors.add(:token, token_status == "expired" ? "has expired" : "is invalid") unless token_status == "valid"
      end
    end
  end
end
