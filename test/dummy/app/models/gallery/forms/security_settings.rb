module Gallery
  module Forms
    class SecuritySettings
      include ActiveModel::Model
      include ActiveModel::Attributes

      SESSION_TIMEOUTS = [ 15, 30, 60, 480 ].freeze

      attribute :current_password, :string
      attribute :new_password, :string
      attribute :two_factor, :boolean, default: true
      attribute :session_timeout, :integer, default: 30

      validates :current_password, presence: true
      validates :new_password, length: { minimum: 12 }
      validates :session_timeout, inclusion: { in: SESSION_TIMEOUTS }
    end
  end
end
