# Inset workspace

**Audience:** Applications composing an inset sidebar workspace.

## Summary

- Use the same balanced inset for sidebar layouts.
- Let navigation own rail padding, the shell own inset geometry, and one
  content wrapper own page gutters.
- Join the sidebar toolbar and main region into one surface; return to
  edge-to-edge content and the native navigation drawer on mobile.

The sidebar layout places navigation in a left rail and the route toolbar in
`shell.topbar`, joined to the content canvas. The other layout, `topbar`, puts
navigation above the content and the page toolbar inside `shell.main`.

## One owner for each spacing decision

| Region                                  | Owner                           | Default                                                                   |
| --------------------------------------- | ------------------------------- | ------------------------------------------------------------------------- |
| Navigation rail padding                 | `AppNavigation`                 | Keep its built-in padding; no additional rail wrapper                     |
| Canvas gap from rail and viewport edges | `AppShell` composition          | Three space units at the canvas top, right, and bottom; no extra rail gap |
| Page gutter                             | One `workspace-content` wrapper | Six space units on desktop, four on mobile                                |
| Space between fields or sections        | The local `Flex`/`Grid`         | No second page gutter                                                     |

With the default space token these are a 12px inset, 24px desktop gutter, and
16px mobile gutter. The topbar uses the same 24px padding on all four sides. The rail uses only its built-in 12px padding, with no extra shell padding
on the left or gap on the right. On mobile, hide the brand and place
the title after the navigation button, with the action at the far right. Do not
add padding to the shell sidebar, an outer page container, and the page itself.

## Compose the frame

Use application-owned `data-ui` hooks. This is ordinary application CSS, not a
new component option or a copied Nitro component. For a sidebar screen:

```ruby
AppShell(id: "workspace", layout: :sidebar, data: { ui: "inset-workspace" }) do |shell|
  shell.brand { strong { "Studio" } }
  shell.navigation do
    AppNavigation(label: "Main navigation") do |navigation|
      navigation.body do
        navigation.item("Products", href: products_path, current: true)
        navigation.spacer
        navigation.item("Settings", href: settings_path)
      end
    end
  end
  shell.topbar do
    Toolbar do |toolbar|
      toolbar.leading { h1 { "Products" } }
      toolbar.trailing { Button("New product", href: new_product_path, variant: :primary) }
    end
  end
  shell.main do
    div(data: { ui: "workspace-content" }) { render ProductsIndex.new(products:) }
  end
end
```

For `topbar`, put that Toolbar first inside `workspace-content` and omit
`shell.topbar`. Keep one route title and one set of actions. The header and
body in `sidebar` form one continuous canvas, not two stacked cards.

Load this stylesheet after Nitro Kit:

```css
/* Application composition: navigation owns its rail padding, this shell owns
   the inset, and workspace-content owns the only page gutter. */
:where([data-ui="workspace-content"]) {
  padding: calc(var(--nk-space) * 4);
}
@media (width >= 48rem) {
  :where([data-ui="inset-workspace"]) {
    --workspace-inset: calc(var(--nk-space) * 3);
    --nk-app-shell-background: color-mix(
      in oklab,
      var(--nk-color-muted) 15%,
      var(--nk-color-canvas)
    );
    --nk-app-shell-sidebar-background: transparent;
    block-size: 100vh;
    block-size: 100dvh;
    padding: var(--workspace-inset) var(--workspace-inset) var(
        --workspace-inset
      ) 0;
    grid-template-rows: auto minmax(0, 1fr);
    column-gap: 0;
    overflow: hidden;
  }
  :where([data-ui="inset-workspace"] > [data-slot="app-shell-sidebar"]) {
    position: static;
    block-size: 100%;
    border: 0;
  }
  :where(
      [data-ui="inset-workspace"]
        > [data-slot="app-shell-header"]
        > [data-slot="app-shell-brand"]
    ) {
    padding-inline: calc(var(--nk-space) * 6);
    border: 0;
  }
  :where([data-ui="inset-workspace"] > [data-slot="app-shell-main"]) {
    overflow: auto;
    overscroll-behavior: contain;
    background: var(--nk-color-surface);
    border: var(--nk-border-width) solid var(--nk-color-border);
    border-radius: var(--nk-radius-xl);
    box-shadow: var(--nk-shadow-sm);
  }
  :where(
      [data-ui="inset-workspace"][data-layout="sidebar"]
        > [data-slot="app-shell-header"]
        > [data-slot="app-shell-topbar"]
    ) {
    padding: calc(var(--nk-space) * 6);
    background: var(--nk-color-surface);
    border: var(--nk-border-width) solid var(--nk-color-border);
    border-block-end: 0;
    border-radius: var(--nk-radius-xl) var(--nk-radius-xl) 0 0;
  }
  :where(
      [data-ui="inset-workspace"][data-layout="sidebar"]
        > [data-slot="app-shell-main"]
    ) {
    border-block-start: 0;
    border-start-start-radius: 0;
    border-start-end-radius: 0;
  }
  :where([data-ui="workspace-content"]) {
    padding: calc(var(--nk-space) * 6);
  }
}

@media (width < 48rem) {
  :where(
      [data-ui="inset-workspace"]
        > [data-slot="app-shell-header"]
        > [data-slot="app-shell-brand"]
    ) {
    display: none;
  }
  :where(
      [data-ui="inset-workspace"]
        [data-slot="app-shell-topbar"]
        > [data-nk="toolbar"]
    ) {
    flex-direction: row;
    flex-wrap: nowrap;
    align-items: center;
  }
  :where([data-ui="inset-workspace"] [data-slot="toolbar-trailing"]) {
    margin-inline-start: auto;
    justify-content: flex-end;
    flex-shrink: 0;
  }
}
```

Navigation, mobile disclosure, and focus restoration remain Nitro-owned.
Application code owns the destinations and the composition. The public
Product resource gallery runs the sidebar example with this stylesheet at
`test/dummy/app/assets/stylesheets/inset_workspace.css`.

## Verify the result

At desktop width, check all four exposed gaps, one continuous rounded canvas,
independent main scrolling, and no rail divider stranded in the inset. In dark
mode the main surface must come forward from the quieter frame. At 390px,
verify edge-to-edge content, no document overflow, visible title/actions, and
a working navigation drawer. Include long route and navigation labels and
both empty and long content; do not judge only a short empty screen.
