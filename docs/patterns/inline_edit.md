# Inline edit

Wrap one complete resource region in a stable Turbo Frame. Show, edit, validation failure, success, and Cancel all return that same frame ID.

## Summary

- One complete resource region lives in a stable Turbo Frame; show, edit,
  invalid, success, and Cancel all return that same frame ID.
- Invalid updates render the editing frame with 422; success redirects with 303
  and Turbo extracts the matching read-only frame.
- The show response must contain the same `turbo_frame_tag(dom_id(record))` as
  the edit response.
- Use a Turbo Stream only when the update also changes another region, such as
  a page title or a summary count.

```ruby
module UI
  class ProjectPanel < Phlex::HTML
    include Phlex::Rails::Helpers::DOMID
    include Phlex::Rails::Helpers::TurboFrameTag

    def initialize(project, editing: false)
      @project = project
      @editing = editing
    end

    def view_template
      turbo_frame_tag(dom_id(project)) do
        if editing
          render UI::ProjectFormFields.new(project)
        else
          render NitroKit::Card.new do |card|
            card.title(project.name)
            card.body { project.description }
            card.footer do
              render NitroKit::Button.new("Edit", href: "/projects/#{project.id}/edit")
            end
          end
        end
      end
    end

    private
      attr_reader :project, :editing
  end
end
```

The edit form submits normally within the frame. Its Cancel link targets the resource show action, which returns the read-only frame. Invalid updates render the editing frame with 422. A successful update redirects with 303 to the resource action; Turbo follows the redirect and extracts the matching read-only frame:

```ruby
redirect_to @project, status: :see_other, notice: "Project updated"
```

The show response must contain `turbo_frame_tag(dom_id(project))` just like the edit response. If success renders directly instead, return frame-shaped HTML rather than labeling a bare frame as a Turbo Stream. Use a stream only when the update also changes another region, such as a page title or summary count.

## Tests

Assert every endpoint returns the same `turbo-frame` ID. Cover invalid values remaining visible at 422 and Cancel restoring the read-only view. Add a system test when focus or scroll preservation is important.
