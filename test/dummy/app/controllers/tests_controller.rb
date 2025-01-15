class TestsController < ApplicationController
  def index
    pp("#{Rails.root}/test/dummy/views/tests/examples/**/*.html.erb")
    @tests = Dir["#{Rails.root}/app/views/tests/examples/**/*.html.erb"].map do |path|
      File.basename(path).split(".").first
    end
  end

  def show
    render("tests/examples/#{params[:id]}")
  end
end
