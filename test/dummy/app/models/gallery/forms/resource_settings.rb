module Gallery
  module Forms
    class ResourceSettings
      include ActiveModel::Model
      include ActiveModel::Attributes

      VISIBILITIES = %w[organization administrators].freeze
      RETENTION_PERIODS = [ 30, 90, 180, 365, 730 ].freeze

      attribute :name, :string
      attribute :visibility, :string, default: "organization"
      attribute :retention_days, :integer, default: 365
      attribute :notify_failures, :boolean, default: true

      validates :name, presence: true, length: { maximum: 100 }
      validates :visibility, inclusion: { in: VISIBILITIES }
      validates :retention_days, inclusion: { in: RETENTION_PERIODS }
    end
  end
end
