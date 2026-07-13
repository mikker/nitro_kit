module Gallery
  module Forms
    class ApiKey
      include ActiveModel::Model
      include ActiveModel::Attributes

      ACCESS_LEVELS = %w[read_only read_write].freeze
      EXPIRATIONS = [ 30, 90, 180, 365 ].freeze

      attribute :name, :string
      attribute :access, :string, default: "read_only"
      attribute :expires_in_days, :integer, default: 90

      validates :name, presence: true, length: { maximum: 60 }
      validates :access, inclusion: { in: ACCESS_LEVELS }
      validates :expires_in_days, inclusion: { in: EXPIRATIONS }
    end
  end
end
