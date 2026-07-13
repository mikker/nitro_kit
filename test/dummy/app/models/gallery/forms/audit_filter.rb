module Gallery
  module Forms
    class AuditFilter
      include ActiveModel::Model
      include ActiveModel::Attributes

      CATEGORIES = %w[all access billing data integration security].freeze

      attribute :query, :string
      attribute :category, :string, default: "all"

      validates :query, length: { maximum: 120 }
      validates :category, inclusion: { in: CATEGORIES }
    end
  end
end
