class FileListComponent < Phlex::HTML
  def initialize(component)
    @files = component.all_files
  end

  attr_reader :files

  def view_template
    ul(class: "list-disc list-inside pl-2 text-sm leading-relaxed marker:text-muted-foreground/50") do
      files.each do |path|
        li do
          a(
            href: "https://github.com/mikker/nitro_kit/blob/v#{NitroKit::VERSION}/#{path}",
            target: "blank",
            class: "inline-flex items-center gap-2 hover:underline"
          ) do
            plain(path)
            render(NitroKit::Icon.new(:"arrow-up-right", size: :sm))
          end
        end
      end
    end
  end
end
