class Post
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title
  attribute :publish, :boolean, default: false

  validates :title, presence: true
  validates :publish, inclusion: {in: [true, false]}
end
