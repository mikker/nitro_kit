# Resource form

**Audience:** Coding agents and developers implementing model-backed create
and update forms.

## Summary

- One model-backed Phlex component renders initial and invalid states.
- Rails owns names, values, and errors; Nitro owns presentation.
- Invalid mutations render the same model with `422`; success redirects with
  `303`.
- Use one primary submit: the shell toolbar owns it, or a standalone form keeps
  it inside `form.group`.
- Wrap the form in a Turbo Frame only when it needs an independent lifecycle.

## Form

```ruby
module UI
  class ProjectForm < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def initialize(project, form_id:)
      @project = project
      @form_id = form_id
    end

    def view_template
      render NitroKit::SettingsSection.new(title: "Project details") do |section|
        section.form do
          form_with(
            model: @project,
            builder: NitroKit::FormBuilder,
            id: @form_id
          ) do |form|
            form.group do
              form.field(:name, required: true)
              form.field(:status, as: :select, options: Project.statuses.keys)
              form.field(:description, as: :textarea)
            end
          end
        end
      end
    end
  end
end
```

In an application shell, render one toolbar submit associated through the
native form ID:

```ruby
Button("Save project", type: :submit, form: form_id, variant: :primary)
```

Do not also call `form.submit` in the body. A standalone form without a toolbar
keeps its submit in the same `form.group` as its visible fields.

## Responses

```ruby
if @project.update(project_params)
  redirect_to @project, status: :see_other, notice: "Project updated"
else
  render UI::ProjectForm.new(@project, form_id:),
    status: :unprocessable_entity
end
```

Wrap the component in a stable frame only when embedded in a larger screen.
Use a Turbo Stream only when success updates multiple regions. See
[Inline edit](inline_edit.md).

## Tests

Assert redirect and flash at `303`; submitted values and model errors at `422`;
and the stable frame ID when embedded. Add a system test for focus or
multi-region behavior, not to repeat controller coverage.
