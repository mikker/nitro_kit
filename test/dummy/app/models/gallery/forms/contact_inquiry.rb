module Gallery
  module Forms
    class ContactInquiry
      include ActiveModel::Model
      include ActiveModel::Attributes

      TOPICS = %w[sales enterprise partnerships press].freeze

      attribute :name, :string
      attribute :email, :string
      attribute :company, :string
      attribute :topic, :string
      attribute :message, :string

      validates :name, :email, :topic, :message, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :topic, inclusion: { in: TOPICS }
      validates :name, :company, length: { maximum: 100 }
      validates :message, length: { minimum: 20, maximum: 2_000 }
    end
  end
end
