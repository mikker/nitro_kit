module Gallery
  module Forms
    class TeamMemberAction
      include ActiveModel::Model
      include ActiveModel::Attributes

      ACTIONS = %w[change_role remove].freeze
      ROLES = %w[admin member viewer].freeze

      attribute :action, :string, default: "change_role"
      attribute :member_id, :string
      attribute :role, :string
      attribute :confirmation, :string

      validates :action, inclusion: { in: ACTIONS }
      validates :member_id, inclusion: { in: ->(_record) { Gallery::Data.members.map(&:id) } }
      validates :role, inclusion: { in: ROLES }, if: :change_role?
      validate :confirmation_must_match_member, if: :remove?

      def member
        Gallery::Data.members.find { |candidate| candidate.id == member_id }
      end

      def change_role? = action == "change_role"
      def remove? = action == "remove"

      private

      def confirmation_must_match_member
        errors.add(:confirmation, "must match the member email address") unless confirmation == member&.email
      end
    end
  end
end
