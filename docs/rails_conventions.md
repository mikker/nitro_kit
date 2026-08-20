# Rails conventions for Nitro Kit applications

**Audience:** Coding agents and developers building Rails application features
with Nitro Kit. These are greenfield defaults; preserve established application
conventions unless the task explicitly changes them.

## Domain and tenancy

- Put business rules on domain models. Add service, form, command, or policy
  objects only when a real boundary requires one.
- Scope tenant-owned records through `Current.team` or `Current.account`. Use
  `Current.user` as the actor, not the tenancy boundary.
- For team-aware products, model `User`, `Team`, and `Membership`; roles belong
  to memberships. See [Application foundation](patterns/application_foundation.md).
- Model lifecycle state as a record when it has identity, timing, provenance,
  or behavior.

## Routes and responses

Use REST resources. When an action does not fit the seven standard actions,
find the missing noun:

```ruby
resources :posts do
  resource :publication, only: %i[create destroy], module: :posts
end
```

Keep controllers thin: load through the tenant boundary, invoke the model, and
render or redirect.

- Use `form_with(..., builder: NitroKit::FormBuilder)` for model-backed forms.
- Redirect successful mutations with `status: :see_other`.
- Render the same invalid model with `status: :unprocessable_entity`.
- Keep an HTML response for Turbo-enhanced flows.
- Keep filtering, sorting, and pagination in GET parameters.
- Set Rails flash on the server and render it once through
  `NitroKit::Toast::FlashMessages`.

See [Browser support](browser_support.md) for native month and week input
limitations, and [Hotwire](hotwire.md) for transport choices.

## Page composition

Use one route title, normally the shell toolbar's `h1`. Add another heading
only for a genuinely separate region. Do not repeat the title across a toolbar,
PageHeader, section, Card, and table caption.

Use Card for a bounded object that needs a surface, not as a default wrapper.
Use one application-owned content gutter inside the shell main region. See
[Complete product resource](patterns/crud_resource.md) for CRUD composition.

## Tests

Use Minitest and fixtures. Cover tenant isolation, authorization differences,
lifecycle resources, public visibility, `303` success, `422` validation, and
the HTML fallback. Add browser tests for behavior that request tests cannot
prove, using Capybara waiting assertions instead of sleeps.
