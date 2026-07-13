module Gallery
  module Forms
    class IntegrationConfiguration
      include ActiveModel::Model
      include ActiveModel::Attributes

      EVENTS = %w[deployments incidents security billing].freeze

      attribute :provider, :string
      attribute :destination, :string
      attribute :webhook_url, :string
      attribute :event, :string

      validates :provider, :destination, :webhook_url, :event, presence: true
      validates :webhook_url, format: { with: %r{\Ahttps://[^\s]+\z}, message: "must be an HTTPS URL" }
      validates :event, inclusion: { in: EVENTS }
    end
  end
end
