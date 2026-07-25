module Gallery
  module Forms
    class ApiKeyRevocation
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :key_id, :string
      attribute :acknowledged, :boolean, default: false

      validates :key_id, inclusion: { in: ->(_record) { Gallery::Data.api_keys.map(&:id) } }
      validates :acknowledged, acceptance: true
    end
  end
end
