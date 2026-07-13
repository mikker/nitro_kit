module Gallery
  module Forms
    class AccountCreation
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :name, :string
      attribute :email, :string
      attribute :password, :string
      attribute :terms, :boolean, default: false

      validates :name, presence: true, length: { maximum: 80 }
      validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :password, presence: true, length: { minimum: 12 }
      validates :terms, acceptance: true
    end
  end
end
