# Inline edit

**Audience:** Coding agents and developers editing one resource region in
place with Turbo Frames.

## Summary

- Wrap the complete resource region in one stable Turbo Frame.
- Show, edit, validation failure, success, and Cancel return the same frame ID.
- Invalid updates render with `422`; successful updates redirect with `303`.
- Use a Turbo Stream only when the update changes another region too.

```ruby
turbo_frame_tag(dom_id(project)) do
  if editing
    render UI::ProjectForm.new(project)
  else
    div do
      h2 { project.name }
      render NitroKit::Button.new("Edit", href: edit_project_path(project))
    end
  end
end
```

The edit form submits inside the frame. Cancel links to the show action, whose
response contains the same `turbo_frame_tag(dom_id(project))`. Invalid updates
render the editing frame with `status: :unprocessable_entity`. Success redirects
with `status: :see_other`; Turbo follows it and extracts the matching read-only
frame.

## Tests

Assert the same frame ID on every endpoint, submitted values and errors at
`422`, success at `303`, and Cancel restoring the read-only view. Add a system
test only when focus, scroll, or multi-region behavior matters.
