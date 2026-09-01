---
paths:
  - "schemas/**"
  - "paths/**"
  - "parameters/**"
  - "api.yaml"
  - "getting_started.md"
  - "quick-start.md"
  - "use-cases.md"
  - "best-practices.md"
  - "faq.md"
  - "authentication.md"
  - "tools.md"
---

# Description Formatting Rules

## HTML in descriptions

If a description field contains inline HTML, replace it with a YAML block scalar (`|`) and reformat the content as equivalent plain text or Markdown, preserving the same visual structure:

- `<br/>` or `<br>` → a blank line between paragraphs, or leave as a line break where appropriate
- `<p>...</p>` → a plain paragraph (blank line above and below)
- `<h1>`, `<h2>`, etc. → Markdown headings (`#`, `##`, etc.)
- `<ul>`/`<li>` → Markdown bullet list (`-`)
- `<ol>`/`<li>` → Markdown numbered list (`1.`, `2.`, etc.)
- `<strong>` or `<b>` → `**bold**`
- `<em>` or `<i>` → `*italic*`
- Escaped HTML entities (e.g. `\/`) → unescaped equivalents (`/`)

Always use the `|` block scalar style when the description spans multiple lines. Keep the content and meaning identical. Do not add, remove, or rephrase anything.

Also replace folded scalar (`>`) style with `|` when the description contains `<br/>` or other HTML, since `>` collapses line breaks and makes HTML invisible.

## Anchor links in descriptions

When a description contains an anchor-style link (e.g., `[here](#section/Authentication)` or `[text](#operation/operationId)`), replace it with the equivalent full readme.io absolute URL. Never remove a link or replace it with plain text. Preserve the original meaning and the link itself. Use the URL format:
- Section links: `https://carecloud.readme.io/reference/<section-name>`
- Operation links: `https://carecloud.readme.io/reference/<operationId-lowercase>`

If you are unsure of the correct target URL, ask the user rather than removing the link.
