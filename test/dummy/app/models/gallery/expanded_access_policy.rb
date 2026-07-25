module Gallery
  class ExpandedAccessPolicy
    ROLES = %i[owner administrator member viewer].freeze

    def initialize(role:)
      raise ArgumentError, "Unknown organization role #{role.inspect}" unless ROLES.include?(role)

      @role = role
    end

    attr_reader :role

    def manage_organization?
      role.in?(%i[owner administrator])
    end

    alias :manage_team? :manage_organization?
    alias :manage_resources? :manage_organization?

    def bulk_resources?
      manage_resources?
    end

    def remove_member?(member)
      manage_team? && member.role != :owner
    end

    def delete_resource?(resource)
      role == :owner && resource.status != :syncing
    end
  end
end
