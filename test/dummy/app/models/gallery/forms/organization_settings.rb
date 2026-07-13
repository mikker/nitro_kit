module Gallery
  module Forms
    class OrganizationSettings
      include ActiveModel::Model
      include ActiveModel::Attributes

      DEFAULT_ROLES = %w[member viewer].freeze

      attribute :name, :string
      attribute :slug, :string
      attribute :default_role, :string, default: "member"
      attribute :security_notifications, :boolean, default: true

      validates :name, presence: true, length: { maximum: 100 }
      validates :slug, presence: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
      validates :default_role, inclusion: { in: DEFAULT_ROLES }
    end
  end
end
