class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  Dir["#{Rails.root}/../../app/helpers/nitro_kit/*_helper.rb"].each do |path|
    cnst = ("NitroKit::" + path.split("/").last.split(".").first.camelize).constantize
    helper(cnst)
  end
end
