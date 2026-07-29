module Gallery
  module Forms
    class TeamMemberAction
      include ActiveModel::Model
      include ActiveModel::Attributes

      ACTIONS = %w[change_role remove].freeze
      ROLES = %w[owner admin member viewer].freeze

      attribute :action, :string, default: "change_role"
      attribute :team_id, :string, default: Gallery::Data::CURRENT_TEAM_ID
      attribute :member_id, :string
      attribute :role, :string
      attribute :confirmation, :string

      validates :action, inclusion: { in: ACTIONS }
      validates :team_id, inclusion: { in: ->(_record) { Gallery::Data.teams.map(&:id) } }
      validates :member_id, inclusion: {
        in: ->(record) { Gallery::Data.memberships(team_id: record.team_id).map(&:id) }
      }
      validates :role, inclusion: { in: ROLES }, if: :change_role?
      validate :confirmation_must_match_member, if: :remove?
      validate :team_must_keep_an_owner, if: :removes_last_owner?

      def member
        team_memberships.find { |candidate| candidate.id == member_id }
      end

      def change_role? = action == "change_role"
      def remove? = action == "remove"

      private

      def confirmation_must_match_member
        errors.add(:confirmation, "must match the member email address") unless confirmation == member&.email
      end

      def removes_last_owner?
        member&.role == :owner && team_owners.one? && (remove? || (change_role? && role != "owner"))
      end

      def team_must_keep_an_owner
        attribute = change_role? ? :role : :base
        errors.add(attribute, "cannot be changed because every team must keep at least one owner")
      end

      def team_owners
        team_memberships.select { |candidate| candidate.role == :owner }
      end

      def team_memberships
        Gallery::Data.memberships(team_id:)
      end
    end
  end
end
