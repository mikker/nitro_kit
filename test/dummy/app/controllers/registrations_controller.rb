class RegistrationsController < ApplicationController
  def new
    render RailsIntegration::RegistrationForm.new(Registration.new)
  end

  def show
    render RailsIntegration::RegistrationSuccess.new
  end

  def create
    @registration = Registration.new(registration_params)
    @registration.valid? ? render_success : render_errors
  end

  private
    def render_success
      respond_to do |format|
        format.turbo_stream { render RailsIntegration::RegistrationStream.new(@registration, success: true) }
        format.html { redirect_to registration_path, status: :see_other }
      end
    end

    def render_errors
      respond_to do |format|
        format.turbo_stream do
          render RailsIntegration::RegistrationStream.new(@registration), status: :unprocessable_entity
        end
        format.html do
          render RailsIntegration::RegistrationForm.new(@registration), status: :unprocessable_entity
        end
      end
    end

    def registration_params
      params.expect(registration: [ :email, :role, :terms, :source, :attachment ])
    end
end
