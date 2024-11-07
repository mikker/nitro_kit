class PagesController < ApplicationController
  def index
  end

  def show
    if available_pages.include?(params[:page])
      render(params[:page])
    else
      render(file: "public/404.html", status: 404, layout: false)
    end
  end

  private

  def available_pages
    @available_pages ||= Dir[Rails.root.join("app/views/pages/*.html.erb")].map do |file|
      file.split("/").last.split(".").first
    end
  end
end
