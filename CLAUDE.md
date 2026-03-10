# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **CareCloud REST API specification** — a modular OpenAPI 3.0.2 specification for the CareCloud CRM/CDP platform. The spec is maintained as split YAML files and compiled into a single bundled file for validation and documentation.

## Commands

All build/lint tools run via Docker:

```bash
# Bundle modular YAML files into _build/openapi.yaml
bin/swagger-cli.sh

# Lint/validate the bundled specification
bin/redocly-openapi-cli.sh

# Render interactive docs locally at http://localhost:8080/
bin/render-doc.sh
```

The CI pipeline (`.gitlab-ci.yml`) runs `redocly-openapi-cli.sh` against `_build/openapi.yaml`.

### Workflow after any change

Always run in this order:
1. `bin/swagger-cli.sh` — bundle the spec
2. `bin/redocly-openapi-cli.sh` — validate the bundle

If either step fails, fix the error and **repeat both steps from the start**. The most common errors are broken `$ref` paths and typos in property names. The validator (Redocly) catches these and will block progress until resolved.

Run the full bundle → lint cycle automatically after **every editing session** — including when the user asks to commit or says they are done.

## Architecture

The spec is split into modular files referenced from `api.yaml`:

```
api.yaml                    ← Entry point; references all sections below
├── paths/_index.yaml       ← Endpoint definitions (~282 files, organized by resource)
├── schemas/_index.yaml     ← Reusable data models (~149 files)
├── parameters/_index.yaml  ← Reusable query/header params (pagination, sorting, filters)
└── responses/_index.yaml   ← Standard HTTP response templates
```

`_build/openapi.yaml` is the compiled output — edit the source files, not this file.

### Two API Interfaces

All endpoints are served under one of two interfaces, controlled by the `{api_interface}` server variable:

- **`enterprise-interface`** — For backend/POS/BI integrations. Uses Bearer token auth.
- **`customer-interface`** — For mobile apps and web microsites. Uses Bearer token auth. Some resources (e.g., `Tokens`, `Users`) are exclusive to one interface.

### Endpoint File Naming

Files under `paths/` are named descriptively in PascalCase after the resource or action they represent:

- **List endpoint** — plural resource name, e.g., `Customers.yaml`, `Cards.yaml`
- **Single resource endpoint** — singular resource name, e.g., `Customer.yaml`, `Card.yaml`
- **Action endpoint** — descriptive action name, e.g., `CustomerAuthToken.yaml`, `CardAssign.yaml`, `CardGenerateDigital.yaml`
- **Sub-resource relationship** — `Sub` prefix followed by the relationship name, e.g., `SubCardTypeCards.yaml`, `SubCampaignProductStoreRecords.yaml`

### Patterns and Conventions

Follow existing file and schema patterns strictly. If you notice conflicting patterns across files, **do not guess which one is correct** — flag the conflict to the user and ask how to resolve it. Log conflicts that require a breaking change to resolve (they can be addressed in the next major API version).

### Linking between resources

When a field references an ID or entity from another resource, add a markdown URL link to that endpoint at the end of the field's description. Always link to the list endpoint (e.g., `GET /customers`), not the single-resource endpoint (e.g., `GET /customers/{customer_id}`). Use the full readme.io URL format that is already established across the spec:

```
[GET /customers](https://carecloud.readme.io/reference/getcustomers)
```

The URL slug pattern is: HTTP method + resource name, all lowercase and concatenated — e.g., `getcustomers`, `getstores`, `getbookingticketproperties`, `postpurchasesend`.

There is no OpenAPI standard for cross-referencing operations in description fields. Full absolute URLs are the most portable format across documentation tools.

## Writing Style and Grammar

Apply these rules to all description fields across the spec (paths, schemas, parameters, responses).

### Grammar and spelling
- Fix typos, grammatical errors, and awkward phrasing throughout the spec
- If a sentence is unclear or its meaning is ambiguous, **ask before changing it** — do not guess at intent
- **Never change the meaning of a sentence**, even to improve readability; if a fix would require reinterpreting the original, ask for clarification first

### Language and tone
- Match the tone already used in the spec: professional, factual, and descriptive
- Write for a technical business audience that may not be native English speakers — prefer short, direct sentences over complex constructions
- Spell out terms in full where possible; avoid abbreviations and acronyms unless they are standard in the industry and well-known (for example, API, ID, URL, CRM are acceptable)
- Avoid buzzwords and marketing language; describe what things do, not how impressive they are

### HTML in descriptions

If a description field contains inline HTML, replace it with a YAML block scalar (`|`) and reformat the content as equivalent plain text or Markdown, preserving the same visual structure:

- `<br/>` or `<br>` → a blank line between paragraphs, or leave as a line break where appropriate
- `<p>...</p>` → a plain paragraph (blank line above and below)
- `<h1>`, `<h2>`, etc. → Markdown headings (`#`, `##`, etc.)
- `<ul>`/`<li>` → Markdown bullet list (`-`)
- `<ol>`/`<li>` → Markdown numbered list (`1.`, `2.`, etc.)
- `<strong>` or `<b>` → `**bold**`
- `<em>` or `<i>` → `*italic*`
- Escaped HTML entities (e.g. `\/`) → unescaped equivalents (`/`)

Always use the `|` block scalar style when the description spans multiple lines. Keep the content and meaning identical — do not add, remove, or rephrase anything.

Also replace folded scalar (`>`) style with `|` when the description contains `<br/>` or other HTML, since `>` collapses line breaks and makes HTML invisible.

### Anchor links in descriptions

When a description contains an anchor-style link (e.g., `[here](#section/Authentication)` or `[text](#operation/operationId)`), replace it with the equivalent full readme.io absolute URL. Never remove a link or replace it with plain text — preserve the original meaning and the link itself. Use the URL format:
- Section links: `https://carecloud.readme.io/reference/<section-name>`
- Operation links: `https://carecloud.readme.io/reference/<operationId-lowercase>`

If you are unsure of the correct target URL, ask the user rather than removing the link.

### Examples of the target style
- Instead of: *"Leverage this endpoint to seamlessly sync customer data"* → write: *"Use this endpoint to synchronize customer data"*
- Instead of: *"Utilize the ID param"* → write: *"Use the ID parameter"*

## Common Tasks

### Backward compatibility (critical)

If a requested change would break backward compatibility, **always notify the user and ask for explicit confirmation before applying it** — even if the user seems to have requested it. It may be a mistake. Only proceed after receiving clear confirmation.

This API must remain backward compatible within the current major version. All changes must follow these rules:

- **Adding query parameters** — always optional, never required; include a description and an example
- **Extending request/response bodies** — new fields must be optional; do not remove or rename existing fields
- **Deprecating parameters** — mark with `deprecated: true` and add a description explaining the replacement; never remove in the same major version
- **Modifying descriptions** — safe to change at any time; keep consistent tone and style with surrounding text
- **Linking resources** — use `$ref` to existing schemas/parameters rather than duplicating definitions; check `schemas/_index.yaml` and `parameters/_index.yaml` before creating anything new

### Key Resource Categories

| Domain | Resources |
|--------|-----------|
| Core CRM | Customers, Cards, Statuses, Customer properties, Segments |
| Transactions | Purchases, Orders, Credits, Points, Wallet |
| Products | Products, Product groups, Brands, Reservations |
| Loyalty | Rewards, Vouchers, Stamper |
| Marketing Automation | Events, Event types, Event groups, Campaigns, Messages |
| Operational | Stores, Users, Partners, Tasks, Tokens |
