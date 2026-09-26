// Layout audit for stress examples.
//
// Evaluates to a function that inspects the current document and returns an
// array of violations. It is a standalone file so the same audit can run from
// Minitest (test/system/stress_sweep_test.rb) and from a browser console or an
// agent-driven browser during manual QA:
//
//   evaluate_script("#{File.read(path)}(arguments[0])", { root: "...", ignore: [] })
//
// Options:
//   root      CSS selector for the region to audit (default: the example canvas).
//   ignore    CSS selectors; matching elements and their descendants are skipped.
//   tolerance Pixels of slack before a measurement counts (default: 1).
//
// Rules:
//   document-overflow  The document is wider than the viewport.
//   outside-viewport   A visible element extends beyond the viewport and no
//                      scroll container owns it.
//   clipped-content    A visible element extends beyond an ancestor that hides
//                      or clips overflow, so part of it can never be seen.
//   text-overflow      Text-bearing box with visible overflow whose content is
//                      wider than the box: it paints over its neighbours.
//   clipped-text       Text-bearing box that hides its own overflow without an
//                      ellipsis: text is cut mid-letter.
//   sibling-overlap    Two in-flow siblings occupy the same pixels. Siblings
//                      with negative margins (AvatarStack) and siblings placed
//                      in the same explicit grid cell (a native control layered
//                      under its custom indicator) are exempt.
//
// Elements with a transform are exempt from bounds rules, since a scaled or
// translated layer is a deliberate visual effect rather than a leak.
(function (options) {
  options = options || {};
  const rootSelector = options.root || "[data-gallery='example-canvas']";
  const tolerance = options.tolerance == null ? 1 : options.tolerance;
  const ignore = options.ignore || [];
  const violations = [];
  const viewportWidth = document.documentElement.clientWidth;

  const documentWidth = Math.max(
    document.documentElement.scrollWidth,
    document.body.scrollWidth,
  );
  if (documentWidth > viewportWidth + tolerance) {
    violations.push({
      rule: "document-overflow",
      element: "html",
      detail: `${documentWidth}px document in ${viewportWidth}px viewport`,
    });
  }

  const roots = Array.from(document.querySelectorAll(rootSelector));
  if (roots.length === 0) {
    violations.push({
      rule: "missing-root",
      element: rootSelector,
      detail: "no audit root found",
    });
    return violations;
  }

  function describe(element) {
    const parts = [];
    let node = element;
    while (node && node.nodeType === 1 && parts.length < 4) {
      let part = node.tagName.toLowerCase();
      if (node.id) {
        part += `#${node.id}`;
      } else {
        if (node.dataset.nk) part += `[data-nk=${node.dataset.nk}]`;
        if (node.dataset.slot) part += `[data-slot=${node.dataset.slot}]`;
      }
      parts.unshift(part);
      if (node.id) break;
      node = node.parentElement;
    }
    return parts.join(" > ");
  }

  function excerpt(element) {
    return (element.textContent || "").trim().replace(/\s+/g, " ").slice(0, 60);
  }

  function ignored(element) {
    return ignore.some((selector) => element.closest(selector));
  }

  // A one-pixel box is the visually-hidden pattern for assistive text; it is
  // meant to be clipped and never paints.
  function visible(element, rect, style) {
    if (style.display === "none" || style.visibility === "hidden") return false;
    if (rect.width <= 1 && rect.height <= 1) return false;
    return rect.width > 0 && rect.height > 0;
  }

  function hasDirectText(element) {
    for (const node of element.childNodes) {
      if (node.nodeType === 3 && node.textContent.trim()) return true;
    }
    return false;
  }

  // Nearest ancestor (up to and including <body>) that does not let overflow
  // through horizontally, or null when the viewport is the boundary.
  function horizontalBoundary(element) {
    let node = element.parentElement;
    while (node && node !== document.documentElement) {
      const style = getComputedStyle(node);
      if (style.overflowX !== "visible") return { node, style };
      node = node.parentElement;
    }
    return null;
  }

  function pushBounds(element, rect, boundary) {
    if (!boundary) {
      if (rect.right > viewportWidth + tolerance || rect.left < -tolerance) {
        violations.push({
          rule: "outside-viewport",
          element: describe(element),
          detail: `${Math.round(rect.left)}..${Math.round(
            rect.right,
          )}px in ${viewportWidth}px viewport`,
          text: excerpt(element),
        });
      }
      return;
    }

    const scrolls = /(auto|scroll)/.test(boundary.style.overflowX);
    if (scrolls) return;

    const box = boundary.node.getBoundingClientRect();
    if (
      rect.right > box.right + tolerance ||
      rect.left < box.left - tolerance
    ) {
      violations.push({
        rule: "clipped-content",
        element: describe(element),
        detail: `${Math.round(rect.left)}..${Math.round(
          rect.right,
        )}px clipped by ${describe(boundary.node)} at ${Math.round(
          box.left,
        )}..${Math.round(box.right)}px`,
        text: excerpt(element),
      });
    }
  }

  function inFlowChildren(element) {
    return Array.from(element.children).filter((child) => {
      const style = getComputedStyle(child);
      const rect = child.getBoundingClientRect();
      return (
        visible(child, rect, style) &&
        !ignored(child) &&
        style.display !== "inline" &&
        style.display !== "contents" &&
        (style.position === "static" || style.position === "relative") &&
        parseFloat(style.marginLeft) >= 0 &&
        parseFloat(style.marginRight) >= 0 &&
        parseFloat(style.marginTop) >= 0 &&
        parseFloat(style.marginBottom) >= 0
      );
    });
  }

  // Children that name the same grid line are layered on purpose.
  function sameGridCell(a, b) {
    const sa = getComputedStyle(a);
    const sb = getComputedStyle(b);
    return (
      sa.gridRowStart !== "auto" &&
      sa.gridColumnStart !== "auto" &&
      sa.gridRowStart === sb.gridRowStart &&
      sa.gridColumnStart === sb.gridColumnStart
    );
  }

  for (const root of roots) {
    const elements = [root, ...root.querySelectorAll("*")];

    for (const element of elements) {
      if (ignored(element)) continue;
      // Native listbox options are laid out by the browser and scroll inside
      // their select; they are not Nitro's to wrap.
      if (element.tagName === "OPTION" || element.tagName === "OPTGROUP")
        continue;

      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      if (!visible(element, rect, style)) continue;

      if (style.position !== "fixed" && style.transform === "none") {
        pushBounds(element, rect, horizontalBoundary(element));
      }

      const inline = style.display === "inline";
      const overflowing = element.scrollWidth > element.clientWidth + tolerance;

      if (!inline && overflowing && hasDirectText(element)) {
        if (style.overflowX === "visible") {
          violations.push({
            rule: "text-overflow",
            element: describe(element),
            detail: `${element.scrollWidth}px content in ${element.clientWidth}px box`,
            text: excerpt(element),
          });
        } else if (
          /(hidden|clip)/.test(style.overflowX) &&
          style.textOverflow !== "ellipsis"
        ) {
          violations.push({
            rule: "clipped-text",
            element: describe(element),
            detail: `${element.scrollWidth}px content in ${element.clientWidth}px box without an ellipsis`,
            text: excerpt(element),
          });
        }
      }

      const children = inFlowChildren(element);
      const grid = /grid/.test(style.display);
      for (let i = 0; i < children.length; i += 1) {
        for (let j = i + 1; j < children.length; j += 1) {
          if (grid && sameGridCell(children[i], children[j])) continue;
          const a = children[i].getBoundingClientRect();
          const b = children[j].getBoundingClientRect();
          const x = Math.min(a.right, b.right) - Math.max(a.left, b.left);
          const y = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top);
          if (x > 2 && y > 2) {
            violations.push({
              rule: "sibling-overlap",
              element: describe(element),
              detail: `${describe(children[i])} overlaps ${describe(
                children[j],
              )} by ${Math.round(x)}×${Math.round(y)}px`,
            });
          }
        }
      }
    }
  }

  return violations;
});
