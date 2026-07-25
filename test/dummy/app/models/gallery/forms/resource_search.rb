module Gallery
  module Forms
    class ResourceSearch
      include ActiveModel::Model
      include ActiveModel::Attributes

      STATUSES = %w[all healthy degraded syncing read_only].freeze
      KINDS = %w[all dataset stream index archive].freeze

      attribute :query, :string
      attribute :status, :string, default: "all"
      attribute :kind, :string, default: "all"

      validates :query, length: { maximum: 120 }
      validates :status, inclusion: { in: STATUSES }
      validates :kind, inclusion: { in: KINDS }
    end
  end
end
