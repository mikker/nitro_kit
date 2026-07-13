module Gallery
  module Forms
    class ActivityFilter
      include ActiveModel::Model
      include ActiveModel::Attributes

      OUTCOMES = %w[all success pending warning blocked].freeze

      attribute :query, :string
      attribute :outcome, :string, default: "all"

      validates :query, length: { maximum: 120 }
      validates :outcome, inclusion: { in: OUTCOMES }
    end
  end
end
