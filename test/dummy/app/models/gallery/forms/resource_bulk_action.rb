module Gallery
  module Forms
    class ResourceBulkAction
      include ActiveModel::Model
      include ActiveModel::Attributes

      ACTIONS = %w[export pause_sync archive].freeze

      attribute :resource_ids, default: -> { [] }
      attribute :action, :string
      attribute :confirmed, :boolean, default: false

      validates :resource_ids, length: { minimum: 1 }
      validates :action, inclusion: { in: ACTIONS }
      validates :confirmed, acceptance: true, if: :destructive?

      def destructive?
        action.in?(%w[pause_sync archive])
      end
    end
  end
end
