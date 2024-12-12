module ExamplesHelper
  def example_file(basename)
    render(ExampleComponent.new(basename)) do
      render("examples/#{basename}")
    end
  end

  # deprecated
  def code_example(str = nil, language: :erb, toolbar: true, &block)
    if block_given?
      str = capture(&block)
        .gsub(/{#/, "<%")
        .gsub(/#}/, "%>")
        .strip_heredoc
        .strip
    end

    tag.div(class: "rounded-xl border overflow-hidden") do
      render(CodeComponent.new(str, language:))
    end
  end

  def inline_example(str = nil, language: :erb, toolbar: true, &block)
    if block_given?
      str = capture(&block)
        .gsub(/{%/, "<%")
        .gsub(/%}/, "%>")
        .strip_heredoc
        .strip
    end

    tag.div(class: "rounded-xl border overflow-hidden") do
      render(CodeComponent.new(str, language:))
    end
  end
end
