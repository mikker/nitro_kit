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

Applications should not need to copy Nitro controllers or install a general
polyfill bundle for a Nitro-owned component. Browsers outside a release's matrix
may still work, but Nitro does not promise fixes for them.

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

Browser compatibility is verified against current stable browsers and
representative older releases near the edge of the support window. Compatibility
work prioritizes real Safari and iOS Safari coverage in addition to Chromium;
tests that merely remove an attribute in current Chrome are useful branch tests,
but are not a substitute for the affected browser engine.

Each Nitro release records a dated tested-browser matrix. The rolling policy is
the durable contract; the matrix records the concrete versions used to verify a
particular release.
