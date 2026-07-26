module Gallery
  module Forms
    class ProjectBrief
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :name, :string
      attribute :brief, :string

      validates :name, presence: true
      validates :brief, presence: true
    end
  end
end
