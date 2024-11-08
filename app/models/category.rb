class Category
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :integer
  attribute :name, :string

  validates :name, presence: true

  def self.all
    %w[Apple Orange].each_with_index.map do |name, id|
      new(name:, id:)
    end
  end
end
