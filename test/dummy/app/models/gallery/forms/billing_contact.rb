module Gallery
  module Forms
    class BillingContact
      include ActiveModel::Model
      include ActiveModel::Attributes

      COUNTRIES = %w[DK DE GB US].freeze

      attribute :company_name, :string
      attribute :billing_email, :string
      attribute :country, :string
      attribute :tax_id, :string

      validates :company_name, presence: true
      validates :billing_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :country, inclusion: { in: COUNTRIES }
    end
  end
end
