# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **specification for CareCloud REST APIs**, a modular OpenAPI 3.0.2 specification for the CareCloud CRM/CDP platform. The specification is maintained as split YAML files and compiled into a single bundled file for validation and documentation.

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
1. `bin/swagger-cli.sh` to bundle the specification
2. `bin/redocly-openapi-cli.sh` to validate the bundle
3. Spawn a Sonnet agent to review the language quality of every file that was modified in the current editing session

If step 1 or 2 fails, fix the error and **repeat both steps from the start**. The most common errors are broken `$ref` paths and typos in property names. The validator (Redocly) catches these and will block progress until resolved.

Run all three steps automatically after **every editing session**, including when the user asks to commit or says they are done.

#### Language review agent (step 3)

Spawn a **Sonnet** agent (`model: sonnet`) that reviews the **full content** of every endpoint, schema, and parameter file modified in the session against the Writing Style and Grammar rules in this file. The agent checks every rule in that section: grammar, audience and tone, and consistency with neighboring fields.

The agent **reports findings only** and does not apply fixes. Each finding must be a **proposed change** containing:
- The current text
- The proposed replacement
- A one-sentence explanation of why the change is needed
- A scope label: **[new]** if the issue was introduced in the current editing session, or **[pre-existing]** if the text existed before this session

Present the proposals to the user for approval. Only apply the changes the user approves. Drop unapproved findings without further action.

## Architecture

The specification is split into modular files referenced from `api.yaml`:

```
api.yaml                    ← Entry point; references all sections below
├── paths/_index.yaml       ← Endpoint definitions (organized into subdirectories by resource)
├── schemas/_index.yaml     ← Reusable data models
├── parameters/_index.yaml  ← Reusable query/header parameters (pagination, sorting, filters)
└── responses/_index.yaml   ← Standard HTTP response templates
```

`_build/openapi.yaml` is the compiled output. Edit the source files, not this file.

Each section uses an `_index.yaml` file as its registry, mapping keys to `$ref` pointers to individual files.

### Paths subdirectory structure

Files under `paths/` are organized into subdirectories by resource type (e.g., `paths/customers/`, `paths/cards/`, `paths/bookings/`). Each subdirectory contains all endpoint files for that resource, including list, single-resource, action, and sub-resource files.

### Two APIs

All endpoints are served under one of two APIs, controlled by the `{api_interface}` server variable:

- **`enterprise-interface`**: for backend/POS/BI integrations. Uses Bearer token auth.
- **`customer-interface`**: for mobile apps and web microsites. Uses Bearer token auth. Some resources (e.g., `Tokens`, `Users`) are exclusive to one API.

API-restricted endpoints include a warning in their `description` field:

```
⚠️ Endpoint is available only in Enterprise API.
⚠️ Endpoint is available only in Customer API.
```

### Endpoint File Naming

Files under `paths/` are named descriptively in PascalCase after the resource or action they represent:

- **List endpoint**: plural resource name
- **Single resource endpoint**: singular resource name
- **Action endpoint**: descriptive action name
- **Sub-resource relationship**: `Sub` prefix followed by the relationship name

### Operation IDs

Every endpoint operation must have an `operationId` following this convention: HTTP verb + resource name in camelCase, e.g., `getCustomers`, `getCustomer`, `postCustomer`, `putCustomer`. The operationId lowercased and concatenated is the slug used in readme.io URLs (e.g., `getcustomers`, `postcustomer`).

### Standard Error Responses

Error responses reference templates via `api.yaml`, not directly to `responses/_index.yaml`.

### Patterns and Conventions

Follow existing file and schema patterns strictly. If you notice conflicting patterns across files, **do not guess which one is correct**. Flag the conflict to the user and ask how to resolve it. Log conflicts that require a breaking change to resolve (they can be addressed in the next major API version).

### Linking between resources

When a field references an ID or entity from another resource, add a markdown URL link to that endpoint at the end of the field's description. Always link to the list endpoint (e.g., `GET /customers`), not the single-resource endpoint (e.g., `GET /customers/{customer_id}`). Use the full readme.io URL format that is already established across the specification:

```
[GET /customers](https://carecloud.readme.io/reference/getcustomers)
```

The URL slug pattern is: HTTP method + resource name, all lowercase and concatenated (e.g., `getcustomers`, `getstores`, `getbookingticketproperties`, `postpurchasesend`).

There is no OpenAPI standard for cross-referencing operations in description fields. Full absolute URLs are the most portable format across documentation tools.

When linking to another endpoint from a description, read the target endpoint file and check whether it carries an API restriction (look for `⚠️ Endpoint is available only in Enterprise API` or equivalent). If it does, note the restriction in the link text, for example:

```
[POST /customers/actions/set-partners](https://carecloud.readme.io/reference/postsubcustomersetpartners) (Enterprise API only)
```

## Developer Portal Documentation

The repository contains markdown files that are manually uploaded to the [CareCloud developer portal](https://carecloud.readme.io/reference). These files are **not part of the OpenAPI specification** and are not processed by the build or validation pipeline (`swagger-cli.sh`, `redocly-openapi-cli.sh`).

| File | Portal page |
|---|---|
| `getting_started.md` | Getting started guide (URI structure, request/response format, pagination, status codes, properties, etc.) |
| `quick-start.md` | Quick-start tutorial for making the first API call |
| `use-cases.md` | Common integration use cases and workflows |
| `best-practices.md` | Integration best practices (rate limiting, error handling, retries) |
| `faq.md` | Frequently asked questions |
| `authentication.md` | Authentication flow details |
| `tools.md` | Developer tools and SDKs |

Some topics are covered in both `api.yaml` `info.description` (rendered by the OpenAPI documentation tool) and a portal markdown file (uploaded separately). When updating such a topic, update both places to keep them consistent.

Other markdown files in the repository root (`bearerAuth.md`, `basicAuth.md`) are referenced via `$ref` from `api.yaml` and are part of the OpenAPI specification. Do not confuse these with the portal files.

## Writing Style and Grammar

Apply these rules to all description fields across the specification (paths, schemas, parameters, responses). The language review agent (step 3 of the post-edit workflow) checks against these same rules.

### Grammar and spelling
- Fix typos, grammatical errors, and awkward phrasing.
- If a sentence is unclear or its meaning is ambiguous, ask before changing it. Do not guess at intent.
- Never change the meaning of a sentence, even to improve readability. If a fix would require reinterpreting the original, ask for clarification first.

### Audience and tone
- Write for a technical business audience that may not be native English speakers. Prefer short, direct sentences over complex constructions.
- Match the existing tone: professional, factual, and descriptive.
- Spell out terms in full. Avoid abbreviations and acronyms unless they are industry standard and well-known (API, ID, URL, CRM are acceptable).
- Avoid buzzwords and marketing language. Describe what things do, not how impressive they are.

### Consistency
- Match how similar fields are described elsewhere in the specification. When adding or editing a field, read neighboring fields in the same schema for phrasing patterns.

### Examples
- Instead of: "Leverage this endpoint to seamlessly sync customer data" write: "Use this endpoint to synchronize customer data."
- Instead of: "Utilize the ID param" write: "Use the ID parameter."

## Common Tasks

### Backward compatibility (critical)

If a requested change would break backward compatibility, **always notify the user and ask for explicit confirmation before applying it**, even if the user seems to have requested it. It may be a mistake. Only proceed after receiving clear confirmation.

This API must remain backward compatible within the current major version. All changes must follow these rules:

- **Adding query parameters**: always optional, never required. Include a description and an example.
- **Extending request/response bodies**: new fields must be optional. Do not remove or rename existing fields. Before removing or renaming a field, verify it exists in the committed specification. A field added in the current editing session is not yet published and can be changed freely. A field present in a prior commit cannot be removed or renamed without a breaking change.
- **Deprecating parameters**: mark with `deprecated: true` and add a description explaining the replacement. Never remove in the same major version.
- **Modifying descriptions**: safe to change at any time. Keep consistent tone and style with surrounding text.
- **Linking resources**: use `$ref` to existing schemas/parameters rather than duplicating definitions. Check `schemas/_index.yaml` and `parameters/_index.yaml` before creating anything new.

### Key Resource Categories

| Domain | Resources |
|--------|-----------|
| Core CRM | Customers, Cards, Statuses, Customer properties, Segments |
| Transactions | Purchases, Orders, Credits, Points, Wallet |
| Products | Products, Product groups, Brands, Reservations |
| Loyalty | Rewards, Vouchers, Stamper |
| Marketing Automation | Events, Event types, Event groups, Campaigns, Messages |
| Operational | Stores, Users, Partners, Tasks, Tokens |
