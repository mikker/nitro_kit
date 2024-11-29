module ExamplesHelper
  def example_file(basename)
    render(ExampleComponent.new(basename)) do
      render("examples/#{basename}")
    end
  end
end
