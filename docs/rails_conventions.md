# The Nitro Kit Rails path

Nitro Kit 2 follows one conventional Rails path so application code, UI, and
agent output compose predictably. Treat this as the greenfield default. In an
existing application, preserve established conventions unless the task
explicitly includes changing them.

## Model the domain with Rails

- Put business rules on domain models. Do not introduce a service, form,
  command, or policy object until a real boundary requires one.
- Scope tenant-owned records through `Current.team` or `Current.account`.
  Record `Current.user` as the actor or creator instead of using the user as
  the tenancy boundary.
- For a new team-aware application, use `User`, `Team`, and `Membership` from
  the first signup. Put roles on the membership and create the first user's
  team plus owner membership in the same transaction. Read
  `docs/patterns/application_foundation.md` before adding authentication,
  invitations, team administration, or account settings.
- Represent meaningful lifecycle state with a record when the state has
  identity, timing, provenance, or behavior. A published post has a
  `Post::Publication`; it is not merely a `published` boolean.
- Name capability concerns with adjectives such as `Publishable` only after
  more than one model shares the behavior. Keep the first implementation on
  the model that owns it.

## Route nouns, not commands

Map controllers to REST resources. When an action does not fit the seven
standard actions, look for the missing noun:

```ruby
namespace :admin do
  resources :posts do
    resource :publication, only: %i[create destroy],
      module: :posts
  end
end
```

`Admin::Posts::PublicationsController#create` publishes and `#destroy`
unpublishes. Keep controllers thin: load through the tenant boundary, invoke a
domain method, then render or redirect.

Use the authenticated admin `show` action as the operational detail or draft
preview unless the product truly has another independently addressable
representation. Public controllers must query only records visible to the
public.

## Use ordinary Rails responses

- Use `form_with` and `NitroKit::FormBuilder` for model-backed forms.
- Redirect successful non-GET submissions with `status: :see_other`.
- Render the same invalid model with `status: :unprocessable_entity`.
- Keep an HTML response for every Turbo-enhanced flow.
- Keep filtering, sorting, and pagination in GET parameters.
- Set flash on the server and render it through
  `NitroKit::Toast::FlashMessages`.

## Compose CRUD as one page

For an authenticated admin or product area, prefer the hybrid `AppShell` with
a `Toolbar` in its topbar. The shell supplies responsive navigation disclosure;
the toolbar supplies the route's one `h1` and its basic actions. The application
owns one content gutter immediately inside the shell main region.

Do not repeat the route title in a `PageHeader`, section heading, card title,
and table caption. Use `PageHeader` inside an application shell only when the
page needs a genuinely content-led introduction beyond the toolbar title. A
single-table index renders the table directly. A form page begins with the
actual `FormSection`. A detail page begins with status or metadata. Use a Card
only for a bounded object that needs a surface, never as the automatic wrapper
for every region.

Read `docs/patterns/crud_resource.md` before building a complete resource.

## Keep the browser thin

Render HTML on the server. Use Turbo Drive by default, Frames for one stable
region, request Streams for multi-target responses, broadcasts for other
sessions, and Stimulus only for browser-owned behavior. Do not create a JSON
API or client-side state store for an ordinary Rails screen.

## Test the contract

Use Minitest and fixtures. Cover:

- tenant isolation and role differences;
- public visibility of drafts and published records;
- successful `303` redirects and invalid `422` renders;
- the noun resource that creates or removes lifecycle state;
- the HTML fallback before adding a system test;
- browser behavior with Capybara waiting assertions, never sleeps.

Prefer a small complete test over layers of factories, mocks, and helper DSLs.
