module Gallery
  module Forms
    class SubscriptionCancellation
      include ActiveModel::Model
      include ActiveModel::Attributes

      REASONS = %w[too_expensive missing_feature temporary_pause switching_service other].freeze

      attribute :reason, :string
      attribute :feedback, :string
      attribute :confirmed, :boolean, default: false

      validates :reason, inclusion: { in: REASONS }
      validates :feedback, length: { maximum: 500 }
      validates :confirmed, acceptance: true
    end
  end
end
