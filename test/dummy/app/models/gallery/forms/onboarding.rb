module Gallery
  module Forms
    class Onboarding
      include ActiveModel::Model
      include ActiveModel::Attributes

      STEPS = %w[workspace team integrations review].freeze
      TEAM_SIZES = [ 1, 5, 20, 50 ].freeze
      INTEGRATIONS = %w[none github slack].freeze

      attribute :step, :string, default: "workspace"
      attribute :workspace_name, :string
      attribute :team_size, :integer
      attribute :invitees, :string
      attribute :integration, :string, default: "none"
      attribute :terms, :boolean, default: false

      validates :step, inclusion: { in: STEPS }
      validates :workspace_name, presence: true, length: { maximum: 80 }
      validates :team_size, inclusion: { in: TEAM_SIZES }
      validates :integration, inclusion: { in: INTEGRATIONS }
      validates :terms, acceptance: true
      validate :invitees_must_be_email_addresses

      def invitee_emails
        invitees.to_s.lines.map(&:strip).reject(&:blank?)
      end

      private

      def invitees_must_be_email_addresses
        invalid_email = invitee_emails.find { |email| !email.match?(URI::MailTo::EMAIL_REGEXP) }
        errors.add(:invitees, "must contain one email address per line") if invalid_email
      end
    end
  end
end
