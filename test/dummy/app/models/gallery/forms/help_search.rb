module Gallery
  module Forms
    class HelpSearch
      include ActiveModel::Model
      include ActiveModel::Attributes

      CATEGORIES = %w[all billing data integrations security support].freeze

      attribute :query, :string
      attribute :category, :string, default: "all"

      validates :query, length: { maximum: 120 }
      validates :category, inclusion: { in: CATEGORIES }
    end
  end
end
