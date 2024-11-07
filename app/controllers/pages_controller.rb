class PagesController < ApplicationController
  def index
  end

  def show
    render(params[:page])
  rescue ActionView::MissingTemplate
    render(file: "public/404.html", status: 404, layout: false)
  end
end
