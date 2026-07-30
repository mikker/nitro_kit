module RailsIntegration
  class RegistrationStream < Phlex::HTML
    include Phlex::Rails::Helpers::DOMID
    include Phlex::Rails::Helpers::TurboStream

    def initialize(registration, success: false)
      @registration = registration
      @success = success
    end

    def view_template
      turbo_stream.replace(target) do
        if success?
          render RegistrationSuccess.new(registration:, frame_id: target)
        else
          render RegistrationForm.new(registration)
        end
      end
    end

    private

    attr_reader :registration

    def success? = @success

    def target = dom_id(registration, :form)
  end
end
