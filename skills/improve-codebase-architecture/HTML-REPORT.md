# HTML Report Format

The architectural review is a single self-contained HTML file in the OS temp directory. Tailwind and Mermaid come from CDNs. Mermaid handles graph-shaped diagrams; hand-built divs and inline SVG handle editorial visuals (mass diagrams, cross-sections).

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review — {{repo}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      .seam {
        stroke-dasharray: 4 4;
      }
      .leak {
        stroke: #dc2626;
      }
      .deep {
        background: linear-gradient(135deg, #0f172a, #1e293b);
      }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Header

Repo name, date, legend: solid box = module, dashed line = seam, red arrow = leakage, thick dark box = deep module. No introduction. Straight into candidates.

## Candidate card

Each candidate is one `<article>`:

- **Title**: short, names the deepening (e.g. "Collapse the Order intake pipeline").
- **Badge row**: recommendation strength + dependency category tag (`in-process`, `local-substitutable`, `ports & adapters`, `mock`).
- **Files**: monospaced list, `font-mono text-sm`.
- **Before / After diagram**: the centrepiece. Two columns, side by side.
- **Problem**: one sentence. What hurts.
- **Solution**: one sentence. What changes.
- **Wins**: bullets, ≤6 words each. Glossary terms only.
- **Decision callout** (if applicable): one line in amber box, naming the `prd/decisions.md` entry it contradicts.

No paragraphs. If the diagram needs a paragraph, redraw the diagram.

## Diagram patterns

Pick the pattern that fits. Mix them.

### Mermaid graph

Use for "X calls Y calls Z, and look at the mess." Sequence diagrams for "before: 6 round-trips; after: 1."

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### Hand-built boxes-and-arrows

Modules as `<div>`s with borders. Arrows as inline SVG `<line>` or `<path>`. Use when the "after" diagram needs one thick-bordered deep module with greyed internals.

### Cross-section

Stack horizontal bands (`h-12 border-l-4`) to show layers. Before: 6 thin layers doing nothing. After: 1 thick band.

### Mass diagram

Two rectangles per module: interface surface area vs implementation. Before: nearly equal (shallow). After: interface short, implementation tall (deep).

### Call-graph collapse

Before: tree of function calls as nested boxes. After: collapsed into one box with faded internals.

## Style

- Colour sparingly: one accent (emerald or indigo) + red for leakage + amber for warnings.
- Diagrams ~320px tall so before/after fits side by side.
- `text-xs uppercase tracking-wider` for module labels inside diagrams.

## Top recommendation

One larger card. Candidate name, one sentence on why, anchor link to its card.
