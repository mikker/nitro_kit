module Gallery
  module Forms
    class BulkUserAction
      include ActiveModel::Model
      include ActiveModel::Attributes

      ACTIONS = %w[remind suspend remove].freeze

      attribute :member_ids, default: -> { [] }
      attribute :action, :string
      attribute :confirmed, :boolean, default: false

      validates :member_ids, length: { minimum: 1 }
      validates :action, inclusion: { in: ACTIONS }
      validates :confirmed, acceptance: true, if: :destructive_action?

      private

      def destructive_action?
        %w[suspend remove].include?(action)
      end
    end
  end
end
