module RailsIntegration
  class RegistrationSuccess < Phlex::HTML
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::TurboFrameTag

    def initialize(frame_id: "form_registration")
      @frame_id = frame_id
    end

    def view_template
      turbo_frame_tag(frame_id) do
        h1 { "Registration received" }
        p { "The Rails and Nitro Kit form completed successfully." }
        a(href: new_registration_path) { "Create another" }
      end
    end

    private

    attr_reader :frame_id
  end
end
