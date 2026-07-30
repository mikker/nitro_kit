class Registration
  include ActiveModel::Model
  include ActiveModel::Attributes

  ROLES = %w[developer designer].freeze

  attribute :email, :string
  attribute :role, :string
  attribute :terms, :boolean, default: false
  attribute :note, :string
  attribute :source, :string, default: "rails-integration"
  attribute :attachment

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :terms, acceptance: true
  validates :note, presence: true

  def persisted? = false
end
