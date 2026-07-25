module Gallery
  module OperationsFormExamples
    module_function

    def team_member_action(state = :role_valid)
      attributes = {
        role_valid: {
          action: "change_role",
          member_id: "mem_grace",
          role: "viewer"
        },
        role_invalid: {
          action: "change_role",
          member_id: "mem_grace",
          role: "owner"
        },
        remove_valid: {
          action: "remove",
          member_id: "mem_grace",
          confirmation: "grace@example.test"
        },
        remove_invalid: {
          action: "remove",
          member_id: "mem_grace",
          confirmation: "wrong@example.test"
        }
      }.fetch(state)

      Gallery::Forms::TeamMemberAction.new(**attributes).tap do |form|
        form.validate if %i[role_invalid remove_invalid].include?(state)
      end
    end

    def api_key_revocation(state = :valid)
      attributes = {
        valid: { key_id: "key_production", acknowledged: true },
        invalid: { key_id: "missing", acknowledged: false }
      }.fetch(state)

      Gallery::Forms::ApiKeyRevocation.new(**attributes).tap do |form|
        form.validate if state == :invalid
      end
    end
  end
end
