module RailsIntegration
  class RegistrationForm < Phlex::HTML
    include Phlex::Rails::Helpers::DOMID
    include Phlex::Rails::Helpers::FormWith
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::TurboFrameTag

    def initialize(registration)
      @registration = registration
    end

    def view_template
      turbo_frame_tag(dom_id(registration, :form)) do
        h1 { "Create registration" }

        form_with(
          model: registration,
          url: registration_path,
          builder: NitroKit::FormBuilder,
          id: dom_id(registration, :details)
        ) do |form|
          form.hidden_field(:source)
          form.group do
            form.field(:email, as: :email, description: "We only use this for the receipt", required: true)
            form.field(
              :role,
              as: :select,
              label: "Role",
              options: [ [ "Developer", "developer" ], [ "Designer", "designer" ] ],
              prompt: "Choose a role",
              required: true
            )
            form.field(
              :note,
              as: :textarea,
              label: "Note",
              description: "This submitted content is rendered in the replacement frame.",
              required: true,
              rows: 3
            )
            form.field(:terms, as: :checkbox, label: "I accept the terms", required: true)
            form.field(:attachment, as: :file, label: "Supporting file", accept: "text/plain")
            form.submit("Register", data: { turbo_submits_with: "Registering…" })
          end
        end

        a(href: new_registration_path, data: { turbo_frame: "_top" }) { "Start over" }
      end
    end

    private

    attr_reader :registration
  end
end
