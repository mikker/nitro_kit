class User
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :status, :string

  def self.model_name
    ActiveModel::Name.new(self, nil, "User")
  end

  def to_key
    nil
  end

  def persisted?
    false
  end
end
