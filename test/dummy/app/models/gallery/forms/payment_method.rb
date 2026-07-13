module Gallery
  module Forms
    class PaymentMethod
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :cardholder_name, :string
      attribute :card_number, :string
      attribute :expiry, :string
      attribute :billing_email, :string
      attribute :postal_code, :string

      validates :cardholder_name, presence: true
      validates :card_number, format: { with: /\A\d{16}\z/, message: "must be 16 digits" }
      validates :expiry, format: { with: /\A(?:0[1-9]|1[0-2])\/\d{2}\z/, message: "must use MM/YY" }
      validates :billing_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :postal_code, presence: true
    end
  end
end
