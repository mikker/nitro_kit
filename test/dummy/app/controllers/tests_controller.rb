class TestsController < ApplicationController
  helper_method :tailwind_color_names

  def index
    @tests = Dir["#{Rails.root}/app/views/tests/examples/**/*.html.erb"].map do |path|
      File.basename(path).split(".").first
    end
  end

  def show
    render("tests/examples/#{params[:id]}")
  end

  private

  def tailwind_color_names
    %i[
      gray
      red
      orange
      amber
      yellow
      lime
      green
      emerald
      teal
      cyan
      sky
      blue
      indigo
      violet
      purple
      fuchsia
      pink
      rose
    ]
  end
end
