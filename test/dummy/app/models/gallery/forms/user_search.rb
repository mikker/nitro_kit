module Gallery
  module Forms
    class UserSearch
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :query, :string
      attribute :status, :string, default: "all"

      validates :query, length: { maximum: 120 }
      validates :status, inclusion: { in: %w[all active invited suspended] }
    end
  end
end
