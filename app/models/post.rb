class Post
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title
  attribute :publish, :boolean, default: false
  attribute :kind, :string, default: "article"

  validates :title, presence: true
  validates :publish, inclusion: {in: [true, false]}

  def self.kinds
    %w[article note reference]
  end
end
