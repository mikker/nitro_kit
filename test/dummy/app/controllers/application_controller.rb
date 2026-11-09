class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :prepare_upload_session

  private

  def prepare_upload_session
    session[:gallery_upload_owner] ||= SecureRandom.hex(32)
  end
end
