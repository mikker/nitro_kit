module Gallery
  module FormExamples
    module_function

    def profile(state = :valid)
      build(
        Gallery::Forms::Profile,
        state,
        valid: {
          name: "Ada Lovelace",
          email: "ada@example.test",
          time_zone: "Europe/Copenhagen",
          bio: "Building reliable interfaces for analytical software."
        },
        invalid: {
          name: "",
          email: "not-an-email",
          time_zone: "Mars/Olympus",
          bio: "x" * 281
        }
      )
    end

    def team_invitation(state = :valid)
      build(
        Gallery::Forms::TeamInvitation,
        state,
        valid: {
          email: "katherine@example.test",
          role: "member",
          message: "Join the release planning workspace."
        },
        invalid: {
          email: "missing-at-sign",
          role: "superuser",
          message: "x" * 241
        }
      )
    end

    def api_key(state = :valid)
      build(
        Gallery::Forms::ApiKey,
        state,
        valid: {
          name: "Reporting",
          access: "read_only",
          expires_in_days: 90
        },
        invalid: {
          name: "",
          access: "owner",
          expires_in_days: 7
        }
      )
    end

    def billing_contact(state = :valid)
      build(
        Gallery::Forms::BillingContact,
        state,
        valid: {
          company_name: "Analytical Engines ApS",
          billing_email: "billing@example.test",
          country: "DK",
          tax_id: "DK12345678"
        },
        invalid: {
          company_name: "",
          billing_email: "accounts.example.test",
          country: "XX",
          tax_id: ""
        }
      )
    end

    def build(form_class, state, valid:, invalid:)
      attributes = { valid:, invalid: }.fetch(state)
      form_class.new(**attributes).tap { |form| form.validate if state == :invalid }
    end
    private_class_method :build
  end
end
