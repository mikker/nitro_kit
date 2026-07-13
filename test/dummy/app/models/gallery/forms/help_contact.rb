module Gallery
  module Forms
    class HelpContact
      include ActiveModel::Model
      include ActiveModel::Attributes

      CATEGORIES = %w[billing data integrations security support].freeze

      attribute :email, :string
      attribute :category, :string
      attribute :subject, :string
      attribute :message, :string

      validates :email, :category, :subject, :message, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :category, inclusion: { in: CATEGORIES }
      validates :subject, length: { maximum: 120 }
      validates :message, length: { minimum: 20, maximum: 2_000 }
    end
  end
end
