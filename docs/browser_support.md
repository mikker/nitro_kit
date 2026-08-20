# Browser support

**Audience:** Application developers and coding agents evaluating Nitro Kit
compatibility. Core maintainers use this policy when changing components.

Nitro Kit targets current stable and widely used evergreen Chrome, Edge,
Firefox, macOS Safari, and iOS Safari releases from roughly the previous two
years. Mobile Safari is a first-class target. Browsers outside that window may
work, but are not guaranteed fixes.

Support means essential content and actions remain usable and accessible. It
does not promise pixel-identical rendering, animation, wrapping, or overlay
placement. Nitro adopts modern standards when it can preserve essential
behavior with capability detection and a focused fallback.

Normal support assumes Nitro Kit's documented JavaScript is installed. The
matrix below defines the reduced baseline when Nitro JavaScript, Stimulus, and
Turbo are absent. A server-rendered HTML response is not automatically a JavaScript-free
interaction: it may still be inside a closed dialog or depend
on Turbo transport.

## Without Nitro JavaScript

- **Full** — essential content and actions remain available.
- **Reduced** — useful content or a simpler native interaction remains, but
  part of the defining behavior is absent.
- **Unavailable** — the defining interaction cannot be completed. Critical
  actions need an ordinary server-rendered route outside the component.

| Component or family                                    | Baseline without JavaScript                                                                                                                                   |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Links, Button, ButtonTo, ordinary forms                | **Full.** Native navigation and submission work; Turbo feedback and confirmation do not.                                                                      |
| Input, Select, Textarea, Switch, RadioButton, Checkbox | **Full.** Indeterminate Checkbox is **Reduced** because `indeterminate` is a DOM property.                                                                    |
| Accordion                                              | **Full.** Single grouping is **Reduced** where named `details` is unsupported.                                                                                |
| AppShell                                               | **Full.** Navigation remains in document flow instead of becoming a drawer.                                                                                   |
| Appearance                                             | **Reduced.** CSS follows system preference; a picker cannot persist changes.                                                                                  |
| Avatar                                                 | **Reduced.** The image and fallback render, but image failure does not reveal the fallback.                                                                   |
| Combobox                                               | **Full.** The native Select remains; searchable listbox behavior is absent.                                                                                   |
| Dialog and Sheet                                       | **Reduced** with Invoker Commands; otherwise **Unavailable** while closed.                                                                                    |
| CommandPalette                                         | **Reduced** with Invoker Commands; otherwise **Unavailable** while closed. Search, shortcuts, and Turbo results are absent.                                   |
| Dropdown                                               | **Reduced.** Native Popover works; menu keyboard behavior, focus restoration, trigger-relative placement, and the WebKit outside-pointer fallback are absent. |
| Dropzone                                               | **Full.** The native file input submits; previews, validation feedback, progress, and direct upload are absent.                                               |
| RichTextArea                                           | **Unavailable** unless the host editor provides its own fallback.                                                                                             |
| ProgressiveImage                                       | **Reduced.** The native image loads; enhanced load and error state are absent.                                                                                |
| Tabs                                                   | **Reduced.** All panels remain visible; single-panel selection and keyboard behavior are absent.                                                              |
| Toast                                                  | **Reduced.** Flash content remains; dismissal is absent.                                                                                                      |
| Tooltip                                                | **Reduced.** CSS hover and focus disclosure remain; Escape dismissal is absent.                                                                               |

## Known native limitations

### Month and week inputs

`month` and `week` remain native input types. Some supported browsers expose
text entry without a picker, normalization, or reliable `min`, `max`, and
`step` enforcement. Applications must server-validate `YYYY-MM` or `YYYY-Www`
plus domain range and increment rules. Use an application-owned Select when an
exact bounded choice is required.

### Dialog commands and Popover

Dialog, Sheet, and CommandPalette render declarative `command`/`commandfor`
controls. With Nitro JavaScript installed, the shared controller uses the
native relationship when available and falls back to `showModal()` or `close()`.
Dropdown keeps native Popover as the visibility authority and adds
keyboard, placement, focus, and WebKit outside-pointer behavior.

### CSS feature fallbacks

Typeset uses `@scope` with a low-specificity fallback for browsers that do not
support it. The fallback covers the documented semantic text elements, not
every possible descendant selector.

## Release verification

Automated CI runs the full system suite in Chrome and priority browser smoke
coverage in Firefox and macOS Safari. Before a release, maintainers also verify
the priority flows on current Android Chrome and iOS Safari. Capability-focused
tests supplement these runs; they do not prove an untested historical browser
version.

Release notes must record exact browser and device versions actually tested.
Do not publish planned or simulated versions as verified coverage.
