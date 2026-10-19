module Gallery
  class ComboboxRelease
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :title, :string
    attribute :label_ids, default: -> { [] }

    validates :title, presence: true

    def labels
      ComboboxLabels.find_all(Array(label_ids).compact_blank)
    end
  end
end
