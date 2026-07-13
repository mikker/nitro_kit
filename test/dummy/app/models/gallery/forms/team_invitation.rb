module Gallery
  module Forms
    class TeamInvitation
      include ActiveModel::Model
      include ActiveModel::Attributes

      ROLES = %w[admin member viewer].freeze

      attribute :email, :string
      attribute :role, :string, default: "member"
      attribute :message, :string

      validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :role, inclusion: { in: ROLES }
      validates :message, length: { maximum: 240 }
    end
  end
end
