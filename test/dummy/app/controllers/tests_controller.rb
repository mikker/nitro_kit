class TestsController < ApplicationController
  helper_method :tailwind_color_names

  def index
    @tests = Dir["#{Rails.root}/app/views/tests/examples/**/*.html.erb"].map do |path|
      File.basename(path).split(".").first
    end
  end

  def show
    template_name = params[:id]

    # Check if it's an example template first
    example_path = "tests/examples/#{template_name}"
    if template_exists?(example_path)
      render(example_path)
      return
    end

    # Handle test templates with setup
    test_path = "tests/#{template_name}"
    if template_exists?(test_path)
      setup_test_data(template_name)
      render(template: test_path)
      return
    end

    # Fallback to 404 if template doesn't exist
    raise ActionController::RoutingError, "Template not found: #{template_name}"
  end

  private

  def setup_test_data(template_name)
    # Setup data based on template name patterns
    case template_name
    when /select/, /form_builder/
      @user = User.new(status: "active")
    end
  end

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
