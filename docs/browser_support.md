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

Each interactive component classifies its no-JavaScript baseline as full,
reduced, or unavailable. When JavaScript is unavailable and the preferred
native API is also unsupported, the component documentation must state the
limitation and recipes for critical actions must retain an ordinary
server-rendered path where practical.

### Accordion

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

| Target          | Near-floor reference | Current release verification | Method                                                   |
| --------------- | -------------------- | ---------------------------- | -------------------------------------------------------- |
| Chrome desktop  | Chrome 128           | Chrome 151                   | Automated Ubuntu lane                                    |
| Edge desktop    | Edge 128             | Edge 151                     | Manual Chromium release check (same engine as Chrome)    |
| Chrome Android  | Chrome 128           | Chrome 151 on Android        | Manual real-device check                                 |
| Firefox desktop | Firefox 128 ESR      | Firefox 153                  | Automated Ubuntu lane; capability branches are simulated |
| Safari macOS    | Safari 18            | Safari 26.5                  | Automated `macos-latest` Selenium lane                   |
| Safari iOS      | Safari 18 / iOS 18   | Safari 26.5 / iOS 26.5       | Manual real-device release check                         |

The automated matrix intentionally tests current Chrome, Firefox, and macOS
Safari rather than downloading historical binaries. The component system suite
is the mapped smoke set: Dialog, Sheet, CommandPalette, Dropdown, and Accordion
exercise open/close, focus, keyboard, and native/fallback paths; the Typeset
component/gallery coverage covers long and narrow text; and
`ProgressiveControlsTest` plus the Field/Input contract tests cover date,
time, datetime-local, month, and week inputs. Run the full suite for each lane;
the focused classes are the first release triage set.

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
