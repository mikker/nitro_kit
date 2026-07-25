module Gallery
  module SettingsFormExamples
    module_function

    def security(state = :valid)
      attributes = {
        valid: {
          current_password: "correct horse battery staple",
          new_password: "a newer correct horse battery staple",
          two_factor: true,
          session_timeout: 30
        },
        invalid: {
          current_password: "",
          new_password: "short",
          two_factor: false,
          session_timeout: 7
        }
      }.fetch(state)

      build(Gallery::Forms::SecuritySettings, attributes, validate: state == :invalid)
    end

    def notifications(state = :valid)
      attributes = {
        valid: {
          security_alerts: true,
          deployment_alerts: true,
          weekly_digest: false,
          delivery_frequency: "immediately"
        },
        invalid: {
          security_alerts: true,
          deployment_alerts: false,
          weekly_digest: true,
          delivery_frequency: "eventually"
        }
      }.fetch(state)

      build(Gallery::Forms::NotificationSettings, attributes, validate: state == :invalid)
    end

    def appearance(state = :valid)
      attributes = {
        valid: { theme: "system", density: "comfortable", reduce_motion: false },
        invalid: { theme: "sepia", density: "tiny", reduce_motion: true }
      }.fetch(state)

      build(Gallery::Forms::AppearanceSettings, attributes, validate: state == :invalid)
    end

    def build(form_class, attributes, validate:)
      form_class.new(**attributes).tap { |form| form.validate if validate }
    end
    private_class_method :build
  end
end
