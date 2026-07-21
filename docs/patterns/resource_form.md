# Resource form

Use one model-backed component for both the initial form and validation errors. Rails owns field names and errors; Nitro owns form presentation; the response status tells Turbo whether to replace or follow a redirect.

## Phlex form

```ruby
module UI
  class ProjectForm < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def initialize(
      project,
      form_id: ActionView::RecordIdentifier.dom_id(project, :form)
    )
      @project = project
      @form_id = form_id
    end

    def view_template
      render NitroKit::FormSection.new(
        title: project.persisted? ? "Edit project" : "New project",
        description: "Project details are visible to every workspace member."
      ) do |section|
        section.form do
          form_with(
            model: project,
            builder: NitroKit::FormBuilder,
            id: form_id
          ) do |form|
            form.group do
              form.field(:name, required: true, autofocus: true)
              form.field(
                :status,
                as: :select,
                options: Project.statuses.keys.map do |value|
                  [ value.humanize, value ]
                end
              )
              form.field(:description, as: :textarea)
            end
          end
        end
      end
    end

    private
      attr_reader :project, :form_id
  end
end
```

In an application shell, render exactly one primary submit in the route
toolbar and associate it with `form_id`:

```ruby
Button(
  project.persisted? ? "Save project" : "Create project",
  type: :submit,
  form: form_id,
  variant: :primary,
  data: { turbo_submits_with: "Saving…" }
)
```

Do not also call `form.submit` in the form body. Use an in-form submit only
when the form is genuinely standalone and has no toolbar action; put that
submit inside the same `form.group` as its visible fields.

## Controller

Render the same invalid object with 422. Redirect successful HTML submissions with 303.

```ruby
class ProjectsController < ApplicationController
  def create
    @project = Current.account.projects.build(project_params)

    if @project.save
      redirect_to @project, status: :see_other, notice: "Project created"
    else
      render UI::ProjectForm.new(@project), status: :unprocessable_entity
    end
  end

  def update
    @project = Current.account.projects.find(params[:id])

    if @project.update(project_params)
      redirect_to @project, status: :see_other, notice: "Project updated"
    else
      render UI::ProjectForm.new(@project), status: :unprocessable_entity
    end
  end

  private
    def project_params
      params.expect(project: [:name, :status, :description])
    end
end
```

The same response works with Turbo Drive and without it. Wrap this component in a stable Turbo Frame only when the form is embedded in a larger screen and should have an independent lifecycle; [inline edit](inline_edit.md) shows that boundary. Add a Turbo Stream branch only when success must update multiple regions instead of navigating.

## Tests

Assert 303 plus the redirect and flash on success. Assert 422, the submitted value, and the model error on failure. For an embedded form, also assert the stable frame ID. Add a system test for focus or multi-region effects, not merely to restate controller behavior.
