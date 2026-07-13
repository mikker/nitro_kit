module Gallery
  module Forms
    class Profile
      include ActiveModel::Model
      include ActiveModel::Attributes

      TIME_ZONES = [ "UTC", "Europe/Copenhagen", "America/New_York", "Asia/Tokyo" ].freeze

      attribute :name, :string
      attribute :email, :string
      attribute :time_zone, :string
      attribute :bio, :string

      validates :name, presence: true
      validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :time_zone, inclusion: { in: TIME_ZONES }
      validates :bio, length: { maximum: 280 }
    end
  end
end
