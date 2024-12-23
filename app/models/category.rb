# frozen_string_literal: true

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

  def self.pluck(*keys)
    all.map do |c|
      keys.map do |key|
        c.send(key)
      end
    end
  end
end
