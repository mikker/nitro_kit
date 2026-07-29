module Gallery
  module Forms
    class Product
      include ActiveModel::Model
      include ActiveModel::Attributes

      STATUSES = %w[draft active archived].freeze

      attribute :name, :string
      attribute :sku, :string
      attribute :status, :string, default: "draft"
      attribute :price, :float
      attribute :inventory_count, :integer
      attribute :description, :string

      validates :name, presence: true
      validates :sku, presence: true, format: { with: /\A[A-Z]{3}-\d{3}\z/ }
      validates :status, inclusion: { in: STATUSES }
      validates :price, numericality: { greater_than_or_equal_to: 0 }
      validates :inventory_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :description, presence: true, length: { maximum: 240 }
    end
  end
end
