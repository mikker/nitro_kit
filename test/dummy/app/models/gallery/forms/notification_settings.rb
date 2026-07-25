module Gallery
  module Forms
    class NotificationSettings
      include ActiveModel::Model
      include ActiveModel::Attributes

      DELIVERY_FREQUENCIES = %w[immediately hourly daily].freeze

      attribute :security_alerts, :boolean, default: true
      attribute :deployment_alerts, :boolean, default: true
      attribute :weekly_digest, :boolean, default: false
      attribute :delivery_frequency, :string, default: "immediately"

      validates :delivery_frequency, inclusion: { in: DELIVERY_FREQUENCIES }
    end
  end
end
