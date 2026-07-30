module RailsIntegration
  class RegistrationSuccess < Phlex::HTML
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::TurboFrameTag

    def initialize(registration: nil, frame_id: "form_registration")
      @registration = registration
      @frame_id = frame_id
    end

    def view_template
      turbo_frame_tag(frame_id) do
        h1 { "Registration received" }
        p { "The Rails and Nitro Kit form completed successfully." }
        submission_details if registration
        a(href: new_registration_path) { "Create another" }
      end
    end

    private

    attr_reader :frame_id, :registration

    def submission_details
      render StatusPill.new(:received)
      dl(data: { rails_integration: "submitted-registration" }) do
        dt { "Email" }
        dd { registration.email }
        dt { "Submitted note" }
        dd { registration.note }
      end
    end
  end
end
