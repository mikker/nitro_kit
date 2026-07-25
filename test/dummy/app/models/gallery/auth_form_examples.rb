module Gallery
  module AuthFormExamples
    VERIFICATION_TOKEN = "verify_2026_07_katherine".freeze
    INVITATION_TOKEN = "invite_2026_07_analytical_engines".freeze

    module_function

    def sign_in(state = :valid)
      attributes = {
        valid: {
          email: Gallery::Data.auth_identity.email,
          password: "correct horse battery staple",
          remember_me: true
        },
        invalid: {
          email: "missing-at-sign",
          password: "short",
          remember_me: false
        }
      }.fetch(state)

      build(Gallery::Forms::SignIn, attributes, validate: state == :invalid)
    end

    def password_reset(state = :request)
      attributes = {
        request: {
          stage: "request",
          email: Gallery::Data.auth_identity.email
        },
        request_invalid: {
          stage: "request",
          email: "not-an-email"
        },
        update: {
          stage: "update",
          token: VERIFICATION_TOKEN,
          password: "a new correct horse battery staple",
          password_confirmation: "a new correct horse battery staple"
        },
        update_invalid: {
          stage: "update",
          token: VERIFICATION_TOKEN,
          password: "too short",
          password_confirmation: "does not match"
        },
        expired: {
          stage: "update",
          token: VERIFICATION_TOKEN,
          token_status: "expired",
          password: "a new correct horse battery staple",
          password_confirmation: "a new correct horse battery staple"
        }
      }.fetch(state)

      build(
        Gallery::Forms::PasswordReset,
        attributes,
        validate: state.to_s.end_with?("invalid") || state == :expired
      )
    end

    def email_verification(status = :valid)
      build(
        Gallery::Forms::EmailVerification,
        { token: VERIFICATION_TOKEN, token_status: status.to_s },
        validate: status != :valid
      )
    end

    def invitation(state = :valid)
      attributes = {
        valid: {
          token: INVITATION_TOKEN,
          token_status: "valid",
          name: Gallery::Data.auth_identity.name,
          password: "correct horse battery staple",
          terms: true
        },
        invalid: {
          token: INVITATION_TOKEN,
          token_status: "valid",
          name: "",
          password: "short",
          terms: false
        },
        expired: {
          token: INVITATION_TOKEN,
          token_status: "expired",
          name: Gallery::Data.auth_identity.name,
          password: "correct horse battery staple",
          terms: true
        },
        invalid_token: {
          token: "not-a-real-invitation",
          token_status: "invalid",
          name: Gallery::Data.auth_identity.name,
          password: "correct horse battery staple",
          terms: true
        }
      }.fetch(state)

      build(Gallery::Forms::InvitationAcceptance, attributes, validate: state != :valid)
    end

    def account_creation(state = :valid)
      attributes = {
        valid: {
          name: Gallery::Data.auth_identity.name,
          email: Gallery::Data.auth_identity.email,
          password: "correct horse battery staple",
          terms: true
        },
        invalid: {
          name: "",
          email: "missing-at-sign",
          password: "short",
          terms: false
        }
      }.fetch(state)

      build(Gallery::Forms::AccountCreation, attributes, validate: state == :invalid)
    end

    def onboarding(state = :valid, step: "workspace")
      attributes = {
        valid: {
          step:,
          workspace_name: Gallery::Data.auth_identity.workspace,
          team_size: 20,
          invitees: "grace@example.test\nkatherine@example.test",
          integration: "github",
          terms: true
        },
        invalid: {
          step:,
          workspace_name: "",
          team_size: 0,
          invitees: "grace@example.test\nnot-an-email",
          integration: "carrier_pigeon",
          terms: false
        }
      }.fetch(state)

      build(Gallery::Forms::Onboarding, attributes, validate: state == :invalid)
    end

    def build(form_class, attributes, validate:)
      form_class.new(**attributes).tap { |form| form.validate if validate }
    end
    private_class_method :build
  end
end
