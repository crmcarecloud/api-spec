---
paths:
  - "schemas/**"
  - "paths/**"
  - "parameters/**"
  - "api.yaml"
  - "getting_started.md"
---

# Date and Time Field Conventions

Use these labels consistently:
- Date + time field → **Timestamp**
- Date-only field → **Date**
- Time-only field → **Time**

## Format conventions

| Context | Format |
|---|---|
| API response (readOnly) | `YYYY-MM-DD HH:MM:SS` (space-delimited, no timezone indicator) |
| API request (writable) | Accepts `YYYY-MM-DD HH:MM:SS` or ISO-8601 (`YYYY-MM-DDTHH:MM:SS`) |
| Date-only | ISO-8601 `YYYY-MM-DD` |
| Time-only | ISO-8601 `HH:MM:SS` |

All times are always in the **local timezone**, never UTC. State this in every datetime description.

## Description templates

Datetime (readOnly):
```
Timestamp of [event]. Format: `YYYY-MM-DD HH:MM:SS`. All times are in the local timezone.
```

Datetime (writable):
```
Timestamp of [event]. Accepts the format `YYYY-MM-DD HH:MM:SS` or ISO-8601 format (`YYYY-MM-DDTHH:MM:SS`). All times must be in the local timezone.
```

Datetime (query parameter):
```
[Filter context]. Accepts the format `YYYY-MM-DD HH:MM:SS` or ISO-8601 format (`YYYY-MM-DDTHH:MM:SS`). All times are in the local timezone.
```

Date only:
```
[Description] in ISO-8601 format (`YYYY-MM-DD`).
```

Time only:
```
[Description] in ISO-8601 format (`HH:MM:SS`). All times are in the local timezone.
```

## Examples
- readOnly datetime → `"2023-03-28 16:59:49"`
- writable datetime → `"2021-04-14 00:00:00"`
- query parameter datetime → `"2021-01-05 00:00:00"`
- date-only → `"2023-04-01"`
