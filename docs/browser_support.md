# Browser support

Nitro Kit uses modern web standards while keeping core content and actions
usable for the overwhelming majority of people on maintained browsers.

The practical target is current stable and popular evergreen releases from
roughly the two years before each Nitro Kit release. This includes Chrome and
Edge on desktop, Chrome on Android, Firefox, Safari on macOS, and Safari on iOS.
It is a coverage target, not a promise of identical results in every version or
a reason to hold components to the oldest browser's feature set.

Each release's dated test matrix sets the concrete floor using release date and
real-world usage rather than an equal number of major versions. Mobile Safari
is a first-class target, not a reduced mobile tier. Important usage,
accessibility, or platform constraints may justify coverage outside the usual
window.

## Functional baseline

In browsers covered by a release's matrix, Nitro components must keep their
essential content and actions usable. Forms must submit, links must navigate,
disclosures and overlays must open and close, destructive actions must retain a
usable request path, and controls must preserve their accessible names and
keyboard behavior.

Visual and convenience enhancements may degrade when a browser lacks a newer
CSS or platform feature. Exact animation, preferred overlay placement, advanced
text wrapping, and similar polish are not required when the simpler result
remains understandable and operable. Support means usable and accessible, not
pixel-identical presentation or identical convenience behavior.

Nitro prefers approved web standards and native browser behavior, but native is
not synonymous with supported. A newer standard can be adopted before it covers
the practical browser target when Nitro can preserve essential behavior:

1. Keep the standard markup or API as the preferred path.
2. Detect support by capability rather than user agent.
3. Add the smallest Nitro-owned fallback needed to preserve functionality.
4. Use a focused polyfill only when a local fallback cannot provide the
   required semantics.

Typeset is a CSS-only exception to the usual progressive-enhancement note:
its readable source uses `@scope`, while the stylesheet also contains a
low-specificity fallback for engines that do not parse `@scope` (including
Firefox through 145). The fallback provides root typography and explicitly
anchored direct-child rules for headings, flow elements, lists, code/pre, and
tables, plus links within those supported semantic elements and their focus
state. It excludes direct nested
`[data-nk]` and `data-typeset="off"` boundaries and intentionally does not
promise the full descendant styling of the scoped path.

Applications should not need to copy Nitro controllers or install a general
polyfill bundle for a Nitro-owned component. Browsers outside a release's matrix
may still work, but Nitro does not promise fixes for them.

### Month and week inputs

`Input(type: :month)` and `Input(type: :week)`, including the matching `Field`
and `FormBuilder` paths, retain the standard native input types as progressive
enhancement. Desktop Safari and Firefox can expose these controls as text
inputs, and native week selection arrived later on iOS Safari. In those cases a
picker, browser normalization, and enforcement of `min`, `max`, and `step` may
be absent.

Applications must accept and validate the submitted ISO shapes on the server:
`YYYY-MM` for month and `YYYY-Www` for ISO week. They must also validate allowed
ranges and increments as domain rules; the native constraint attributes are
client-side hints, not an authorization or validation boundary. When choosing
only from an exact, bounded set is essential, compose an application-owned
`Select` with explicit month or week options instead of relying on a generic
Nitro datepicker. Ordinary `date`, `time`, and `datetime-local` controls keep
their existing contracts.

## JavaScript and progressive enhancement

Normal support assumes the documented Nitro JavaScript is installed. Nitro is
server-rendered and progressively enhanced, not JavaScript-free. Static content,
links, ordinary forms, and only the component-specific baselines documented in
the component contracts are guaranteed without JavaScript. Turbo transport,
Stimulus enhancements, and compatibility bridges are then unavailable.

The classifications below describe the rendered page with Nitro JavaScript,
Stimulus, and Turbo absent:

- **Full** means the component's essential content and action remain available;
  documented convenience behavior may still be absent.
- **Reduced** means useful content or a simpler native interaction remains, but
  part of the component's defining interaction is absent.
- **Unavailable** means the defining interaction cannot be completed. Critical
  actions need an ordinary server-rendered route outside that component.

A server-rendered HTML response is not automatically a JavaScript-free
interaction. It can still place content in a closed dialog or rely on Turbo to
submit, replace, or confirm. Likewise, an HTML response branch is the fallback
for Turbo transport, not proof that the surrounding control works without
JavaScript.

### No-JavaScript component matrix

| Component or family                                        | Classification                                                     | Concise baseline without JavaScript                                                                                                                                                                                                 |
| ---------------------------------------------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Links, Button, ButtonTo, and ordinary forms                | Full                                                               | Native navigation and submission work. Submission indicators and Turbo transport or confirmation do not.                                                                                                                            |
| Input, Select, Textarea, Switch, RadioButton, and Checkbox | Full; reduced for indeterminate Checkbox                           | Native controls edit and submit. `indeterminate: true` cannot be applied because it is a DOM property; month/week have the separate native-control limitations below.                                                               |
| Accordion                                                  | Full; reduced single grouping where named `details` is unsupported | Every `details` opens and closes. Exclusive grouping depends on native shared-`name` support.                                                                                                                                       |
| AppShell                                                   | Full                                                               | Navigation stays visible in document flow at narrow widths; the enhanced drawer interaction is absent.                                                                                                                              |
| Appearance                                                 | Reduced                                                            | CSS follows the system preference and server-rendered picker state remains visible, but a picker cannot apply or persist a new choice without the bootstrap runtime and controller.                                                 |
| Avatar                                                     | Reduced                                                            | The native image and rendered fallback remain, but a failed image is not swapped to its fallback.                                                                                                                                   |
| Combobox                                                   | Full                                                               | The labelled native Select remains the named control and submission source; searchable listbox behavior is absent.                                                                                                                  |
| Dialog and Sheet                                           | Reduced with Invoker Commands; unavailable without them            | Declarative trigger and close controls work only with native Invoker Commands. A server-open nonmodal Dialog remains visible; controller dismissal policy and the compatibility bridge are absent.                                  |
| CommandPalette                                             | Reduced with Invoker Commands; unavailable without them            | Native commands can open the dialog and its destination links navigate, but search, shortcut, announcements, and Turbo results are absent. Without Invoker Commands the closed content is unreachable.                              |
| Dropdown                                                   | Reduced                                                            | Native Popover opens, closes, and light-dismisses. Menu keyboard conventions, focus restoration, collision-aware placement, and Nitro's outside-pointer compatibility fallback are absent; CSS supplies bounded top-left placement. |
| Dropzone                                                   | Full                                                               | Its labelled native file input and ordinary form submission work; drag preview, policy feedback, progress, and direct upload are absent.                                                                                            |
| RichTextArea                                               | Unavailable unless the host editor provides its own fallback       | Nitro wraps trusted host-editor markup and does not manufacture a plain-text control. The host editor owns its JavaScript and fallback contract.                                                                                    |
| ProgressiveImage                                           | Reduced                                                            | The native image loads and retains its accessible alternative; decode/load state and the visible error fallback are not enhanced.                                                                                                   |
| Tabs                                                       | Reduced                                                            | Every panel and its heading control remain visible and reachable; single-panel selection and APG keyboard behavior are absent.                                                                                                      |
| Toast                                                      | Reduced                                                            | Server-rendered flash content and live-region semantics remain; timed and manual dismissal are absent.                                                                                                                              |
| Tooltip                                                    | Reduced                                                            | CSS hover and focus disclosure remain; Escape dismissal is absent.                                                                                                                                                                  |

Typeset is not interactive, but its no-JavaScript and no-`@scope` CSS path is
also reduced: the fallback covers the documented semantic subset rather than
full descendant parity.

### Compatibility details

#### Accordion

Accordion always keeps native `details` and `summary` as the disclosure
authority. Its no-JavaScript baseline is full for opening and closing each
item. In `single` mode, a shared `name` is the browser-native exclusive-group
mechanism: browsers that support named details provide the full one-open-item
behavior without a Nitro controller.

The short Firefox gap before Firefox 130, including Firefox 128 ESR, has a
reduced `single` baseline: each disclosure still opens and closes normally,
but more than one item can remain open. Nitro does not detect the browser or
install JavaScript merely to duplicate that native grouping. Applications for
which strict one-open-at-a-time behavior is essential in that gap should use a
different interaction with an application-owned server or JavaScript policy.

Browser compatibility is verified against current stable browsers and
representative older releases near the edge of the support window. Compatibility
work prioritizes real Safari and iOS Safari coverage in addition to Chromium;
tests that merely remove an attribute in current Chrome are useful branch tests,
but are not a substitute for the affected browser engine.

Dialog, Sheet, and CommandPalette keep declarative `command`/`commandfor`
controls in their server markup. With Nitro JavaScript installed, their shared
controller uses the reflected invoker relationship when available and falls
back to `HTMLDialogElement.showModal()` or `close()` only when that relationship
cannot run. Without JavaScript, opening and closing these overlays is available
only in browsers with Invoker Commands; destination links and ordinary forms
remain server-rendered, but content inside a closed dialog is not reachable.

Each Nitro release records a dated tested-browser matrix. The rolling policy is
the durable contract; the matrix records the concrete versions used to verify a
particular release.

## Nitro Kit 2.0 release matrix (2026-08-05)

This is the release checklist for the next Nitro 2.0 release. “Automated” means
the Rails/Selenium system suite runs in CI; it does not claim that Selenium
reproduces every device or browser UI detail. Version numbers are the stable
targets recorded on this date, and should be refreshed if the release slips.

| Target          | Near-floor reference | Current release verification | Method                                                |
| --------------- | -------------------- | ---------------------------- | ----------------------------------------------------- |
| Chrome desktop  | Chrome 128           | Chrome 151                   | Automated Ubuntu full-system-suite lane               |
| Edge desktop    | Edge 128             | Edge 151                     | Manual Chromium release check (same engine as Chrome) |
| Chrome Android  | Chrome 128           | Chrome 151 on Android        | Manual real-device check                              |
| Firefox desktop | Firefox 128 ESR      | Firefox 153                  | Automated Ubuntu priority-smoke lane                  |
| Safari macOS    | Safari 18            | Safari 26.5                  | Automated `macos-latest` priority-smoke lane          |
| Safari iOS      | Safari 18 / iOS 18   | Safari 26.5 / iOS 26.5       | Manual real-device release check                      |

The automated matrix intentionally tests current Chrome, Firefox, and macOS
Safari rather than downloading historical binaries. Chrome runs the full
system suite. Firefox and Safari run `bin/browser-smoke`, the single maintained
priority lane for Dialog, Sheet, CommandPalette, Dropdown/AppearancePicker,
Accordion, Hotwire lifecycle, Typeset contracts, and date-family input
behavior. Chrome DevTools emulation remains Chrome-only coverage and is not
presented as cross-engine verification. Priority smoke lanes run with one
worker; Chrome retains the full suite's normal parallelism.

Before release, manually repeat those flows on one current Android Chrome and
one current iPhone Safari, including narrow layout, VoiceOver/TalkBack where
available, real form submission, and month/week ISO values. Record device OS,
browser build, date, and any reduced-baseline behavior in the release notes.
Do not describe the near-floor or iOS rows as automated coverage.

The Firefox 128 ESR and older Safari behavior that cannot be installed
reliably on GitHub-hosted runners is represented by capability-focused tests:
stripping Invoker Commands and exercising Nitro fallbacks, plus the documented
native month/week degradation. These branch simulations supplement, but do not
replace, the dated real-browser checks.
