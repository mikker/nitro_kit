module Gallery
  module Forms
    class AppearanceSettings
      include ActiveModel::Model
      include ActiveModel::Attributes

      THEMES = %w[system light dark].freeze
      DENSITIES = %w[comfortable compact].freeze

      attribute :theme, :string, default: "system"
      attribute :density, :string, default: "comfortable"
      attribute :reduce_motion, :boolean, default: false

      validates :theme, inclusion: { in: THEMES }
      validates :density, inclusion: { in: DENSITIES }
    end
  end
end
