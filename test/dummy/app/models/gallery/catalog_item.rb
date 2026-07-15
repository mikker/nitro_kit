module Gallery
  class CatalogItem < ApplicationRecord
    self.table_name = "gallery_catalog_items"

    STATUSES = %w[active trial paused archived].freeze
    EXAMPLES = [
      { sku: "NK-1001", name: "Atlas Workspace", owner: "Ada Lovelace", status: "active", seats: 42 },
      { sku: "NK-1002", name: "Beacon Studio", owner: "Grace Hopper", status: "trial", seats: 12 },
      { sku: "NK-1003", name: "Cedar Research", owner: "Katherine Johnson", status: "active", seats: 64 },
      { sku: "NK-1004", name: "Delta Systems", owner: "Margaret Hamilton", status: "paused", seats: 18 },
      { sku: "NK-1005", name: "Ember Labs", owner: "Radia Perlman", status: "active", seats: 27 },
      { sku: "NK-1006", name: "Fjord & Co.", owner: "Frances Allen", status: "archived", seats: 8 },
      { sku: "NK-1007", name: "Grove Analytics", owner: "Annie Easley", status: "trial", seats: 15 },
      { sku: "NK-1008", name: "Harbor Health", owner: "Mary Jackson", status: "active", seats: 51 },
      { sku: "NK-1009", name: "Indigo Finance", owner: "Evelyn Boyd Granville", status: "paused", seats: 23 },
      { sku: "NK-1010", name: "Juniper Cloud", owner: "Jean Bartik", status: "active", seats: 36 },
      { sku: "NK-1011", name: "Kite Commerce", owner: "Adele Goldstine", status: "trial", seats: 11 },
      { sku: "NK-1012", name: "Lumen Education", owner: "Karen Spärck Jones", status: "active", seats: 73 },
      { sku: "NK-1013", name: "Morrow Design", owner: "Sister Mary Kenneth Keller", status: "archived", seats: 6 },
      { sku: "NK-1014", name: "Northstar Energy", owner: "Gladys West", status: "active", seats: 49 },
      { sku: "NK-1015", name: "Orbit Legal", owner: "Joan Clarke", status: "paused", seats: 20 }
    ].freeze

    validates :sku, :name, :owner, presence: true
    validates :sku, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :seats, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def self.ransackable_attributes(_auth_object = nil)
      %w[name owner seats sku status updated_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    def self.seed_examples!
      EXAMPLES.each do |attributes|
        record = find_or_initialize_by(sku: attributes.fetch(:sku))
        record.update!(attributes)
      end
    end
  end
end
