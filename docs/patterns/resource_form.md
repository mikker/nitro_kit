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
- Relation pickers use a remote `Combobox` whose `selected:` choices are rebuilt
  from the submitted ids, so an invalid re-render keeps every selection.

## Form

Use one full-width column of fields inside a centered `Container(size: :lg)`
for ordinary resource forms. A `Fieldset` puts its legend above the controls.
Reserve the two-column `SettingsSection` for settings pages with enough room
for both explanatory text and fields; nesting it in a narrow form container
squeezes the controls.

```ruby
module UI
  class ProjectForm < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def initialize(project, form_id:)
      @project = project
      @form_id = form_id
    end

    def view_template
      render NitroKit::Container.new(size: :lg) do
        form_with(
          model: @project,
          builder: NitroKit::FormBuilder,
          id: @form_id
        ) do |form|
          form.fieldset(legend: "Project details") do
            form.field(:name, required: true)
            form.field(:status, as: :select, options: Project.statuses.keys)
            form.field(:description, as: :textarea)
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

## Relation pickers

Pick associated records with a remote `Combobox`. Rails keeps search,
authorization, creation, and persistence; the combobox owns selection state,
stale-search cancellation, loading and error feedback, keyboard navigation, and
chips backed by hidden `name[]` fields.

```ruby
render NitroKit::Combobox.new(
  id: "post-tags",
  name: form.field_name(:tag_ids, multiple: true),
  label: "Tags",
  src: tags_path(combobox: "post-tags"),
  multiple: true,
  selected: @post.tags.map { |tag| { label: tag.name, value: tag.id } }
)
```

Build `selected:` from the model, never from the raw params, so an invalid
`422` re-render shows exactly the records that still exist. On an unsaved
record, `@post.tag_ids = params[:post][:tag_ids]` loads them in memory.

The search endpoint scopes records to the current user and renders
`Combobox::Results` without a layout. An action posts back to the application,
which answers with the record to select:

```ruby
class TagsController < ApplicationController
  def index
    tags = Current.account.tags.search(params[:query]).limit(8)
    render UI::TagResults.new(tags:, query: params[:query]), layout: false
  end

  def create
    tag = Current.account.tags.create_or_find_by!(name: params.require(:tag)[:name])
    render UI::TagResults.new(tags: [ tag ], query: nil), status: :created, layout: false
  end
end

class UI::TagResults < Phlex::HTML
  include Phlex::Rails::Helpers::Routes

  def initialize(tags:, query:)
    @tags = tags
    @query = query.to_s.strip
  end

  def view_template
    render NitroKit::Combobox::Results.new(id: "post-tags") do |results|
      @tags.each { |tag| results.option(tag.name, value: tag.id) }
      if @query.present? && @tags.none? { |tag| tag.name.casecmp?(@query) }
        results.action("Create tag “#{@query}”", url: tags_path, params: { "tag[name]" => @query })
      end
    end
  end
end
```

Respond with a non-success status when creation fails; the combobox shows its
error message and keeps the existing chips. Use a single remote combobox
(without `multiple:`) for a `belongs_to` picker; it submits one hidden
`name` field.

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
