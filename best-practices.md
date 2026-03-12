This page is a checklist of proven integration practices for CareCloud API clients. It applies regardless of whether you are building a POS system, an e-commerce platform, a mobile application, or a customer portal.

The difference between a reliable, maintainable integration and one that causes production incidents is rarely the business logic — it is the handling of edge cases: token expiry, duplicate requests, rate limits, and service unavailability. These topics are covered here.

Read through the full page before writing any integration code. The final two sections summarise which practices are most relevant for server-side and client-side integrations respectively.

---

## 1. Know the API contract

Before writing any integration code, read the full [Getting started guide](https://carecloud.readme.io/reference/getting-started-with-your-api). It documents the URI structure, HTTP verbs, headers, status codes, and error response format.

### Choose the correct interface

CareCloud API provides two HTTP interfaces. Using the wrong one is one of the most common setup errors.

| Interface | URL segment | Designed for |
| --- | --- | --- |
| Enterprise | `enterprise-interface` | POS, e-commerce backends, BI tools, backend data processing |
| Customer | `customer-interface` | Mobile apps, web portals, kiosks, smart devices |

The authentication method and available endpoints differ between interfaces. See [Authentication](https://carecloud.readme.io/reference/authentication) for details.

### Pin the API version

Always include the explicit version segment in your base URL. Do not rely on default routing.

```
https://{project_url}/webservice/rest-api/{api_interface}/v1.0/...
```

If the version segment is omitted and the default changes, your integration may silently start calling a different version.

### Understand the HTTP verbs

CareCloud API uses `GET`, `POST`, `PUT`, and `DELETE`. The distinction between `POST` and `PUT` is critical:

- `POST` — creates a new resource
- `PUT` — replaces an entire resource record

> ❗️ The `PUT` method replaces the entire resource. Any field you omit from the request body will be deleted from the record. Only use `PUT` when you have the complete, current data set for that resource.

For partial updates to a single field, check whether a dedicated action method (`POST .../actions/...`) exists for that operation.

### Know the status codes

CareCloud API returns standard HTTP status codes. Familiarise yourself with what each one means before handling errors in your code — see [Status codes](https://carecloud.readme.io/reference/getting-started-with-your-api#status-codes).

---

## 2. Authentication and token security

### Enterprise interface

The enterprise interface uses Bearer token authentication. Tokens are obtained by calling `POST /users/actions/login` with user credentials and an external application ID.

The response includes a `valid_to` timestamp. The default token validity is 7 hours.

> 🚧 Bearer token validity is configurable per project. Contact your CareCloud administrator if the default expiry does not fit your use case.

When a request returns HTTP `401`, the token has expired or is invalid. Re-authenticate by calling the login endpoint again and retry the request with the new token.

> ❗️ Enterprise credentials and Bearer tokens must be stored only on a secured server. Never include them in mobile app binaries, browser JavaScript, kiosk front-end configuration, or any medium accessible to end users. Any person with access to the device can extract credentials stored in a client-side application and make authenticated requests on behalf of your system.

### Customer interface

The customer interface uses a device token obtained by calling `POST /tokens`. No enterprise credentials are required to create this token.

A token remains valid until a new token is created for the same `device_id` and `external_application_id`. Customer login is optional: it is required only when the customer needs to access personal or purchase data.

See [Customer interface authentication](https://carecloud.readme.io/reference/authentication#customer-interface-http-bearer-authentication) for the full authentication flow.

### Store tokens securely

Never store tokens in source code repositories. Treat tokens as credentials — the same way you would treat a password.

- **Server-side applications:** use environment variables or a secrets manager
- **Mobile applications:** use platform-provided secure storage (iOS Keychain, Android Keystore)
- **Web applications:** use the browser Credential Management API or server-side session storage; do not store tokens in `localStorage` or URL parameters

---

## 3. Efficient data retrieval

### Use pagination

CareCloud API list endpoints return paginated results. Use the `count` and `offset` query parameters to page through results. The `count` parameter defaults to 100; do not assume all records fit in one response.

### Check `total_items` before paginating

Every list response includes a `total_items` field at the root of the `data` object. Read this value before issuing additional page requests. If `total_items` is less than or equal to your `count` value, the first response contains all records and no further pages are needed.

### Filter server-side

Use the available query parameters to narrow results on the server before they are transmitted. Downloading a full dataset and filtering it in your application wastes bandwidth and increases response time, particularly for resources with thousands of records.

### Sort to get relevant records first

Use `sort_field` and `sort_direction` to retrieve the most relevant records in the first page. This reduces the number of pages you need to read in workflows where only recent or top-ranked records matter.

> 📘 Pagination, filtering, and sorting parameters are documented for each endpoint in the API reference.

---

## 4. Local caching

Call an endpoint only when the data is genuinely needed. If your application already holds a result in memory and the underlying data has not changed, use the cached value.

For data that changes infrequently — product catalogues, reward lists, store directories, available currencies — cache the response in application memory, local storage, or a database. Refresh the cache at an interval that reflects how often the data actually changes in your business context.

Data that changes frequently — a customer's point balance, active vouchers, reservation status — should be refreshed more often, and cached for shorter periods.

### Respect server-side caching headers

CareCloud API may return a `Cache-Control` response header containing a `max-age` value (in seconds). If present, the response was cached server-side. Do not poll the endpoint more frequently than this interval.

```Text HTTP response header
Cache-Control: max-age=3600
```

> 📘 For details on how server-side caching works and how to configure it, see [API endpoint caching](https://carecloud.readme.io/reference/getting-started-with-your-api#api-endpoint-caching).

---

## 5. Avoid duplicate requests

Do not call the same endpoint twice within the same request cycle when you already have the result.

If multiple parts of your application need the same data — for example, the customer's loyalty balance shown in a header and in a checkout summary — fetch it once and share the result. Do not allow each component to issue its own independent request.

Track in-flight requests: if a request is already pending, do not issue an identical second request. Wait for the first response and reuse it.

---

## 6. User action debouncing

Any button or interactive element in your application that triggers an API call must be disabled after the first press, until a response is received — whether that response is a success or an error.

Display a loading state while the request is pending.

Without debouncing:

- A user pressing a "Confirm purchase" button twice can create two purchase records
- A "Register" button pressed twice can attempt to create two customer accounts
- A loyalty redemption button pressed twice can redeem a reward twice

> ❗️ This applies to any write operation (`POST`, `PUT`). Read operations (`GET`) are less harmful to duplicate, but still waste resources and increase response time.

---

## 7. Handle rate limiting (HTTP 429)

CareCloud API enforces request rate limits. If you exceed the limit, the API returns HTTP `429 Too Many Requests`.

### Do not retry immediately

Retrying immediately after a `429` response will continue to fail and consumes retry budget. Wait before retrying.

### Recommended approach: exponential backoff with jitter

1. Wait before retrying. Start with a short initial delay (for example, 1 second).
2. Double the delay on each subsequent failure: 1 s → 2 s → 4 s → 8 s...
3. Add a random jitter — for example, ±20% of the current wait time. This prevents multiple instances of your application from retrying in lockstep, which would recreate the original request burst.
4. Set a maximum retry count. After that limit, stop retrying, log the failure, and alert if appropriate.

### Other rate-limiting techniques

| Technique | How it works |
| --- | --- |
| Linear backoff | Fixed delay between retries (simpler than exponential, less effective under sustained load) |
| Token bucket | Pre-limit your own outgoing request rate before sending, rather than reacting after rejection |
| Circuit breaker | Stop sending requests to a failing service for a defined period; probe with one request before resuming normal traffic |

> 📘 If you are building a background data synchronisation job, implement a request queue with a configurable rate limiter rather than sending requests as fast as possible.

---

## 8. Handle errors and service unavailability

### HTTP 400 — Bad request

Read the `reason` field in the response body. It identifies the specific problem. React to each reason specifically rather than displaying a generic error message.

Common reason values: `already_exists`, `not_found`, `invalid_value_format`, `required`, `not_allowed_value`, `empty`, `relation_already_exists`.

The full list of reason codes is documented in the [Getting started guide](https://carecloud.readme.io/reference/getting-started-with-your-api#list-or-all-error-reasons-from-general-api-endpoints).

### HTTP 401 — Unauthorised

The token is missing, expired, or invalid. Re-authenticate and retry the request once with the new token.

### HTTP 403 — Forbidden

The client does not have access to this resource. Do not retry. Fix the credentials or the permissions assigned to the external application.

### HTTP 404 — Not found

The requested resource does not exist. Check the resource ID and the URL for typos before retrying.

### HTTP 500 / 503 — Server error or temporary unavailability

Apply the same exponential backoff strategy described in [section 7](#7-handle-rate-limiting-http-429). Do not retry indefinitely.

### Configure HTTP client timeouts

Set both a connection timeout and a read timeout in your HTTP client:

- **Connection timeout** — how long to wait for the TCP connection to be established
- **Read timeout** — how long to wait for the response after the connection is open

Without explicit timeouts, a slow or unresponsive API endpoint can hang your application thread indefinitely. Read timeouts of 10–30 seconds are a reasonable starting point for synchronous API calls; adjust based on your use case.

> 📘 Log all non-2xx responses, including the full response body. This is the first piece of information you will need when debugging a production incident. Be mindful of personally identifiable information — mask or omit sensitive fields such as email addresses, phone numbers, and card numbers from logs.

---

## 9. Push notification campaigns

If your system sends push notifications to customers, and those notifications cause the customer's application to make API calls, be aware of the thundering herd problem: delivering a push notification to thousands of devices simultaneously causes all of those applications to call the API at the same moment.

This can exceed rate limits and degrade API performance for all users — not just those receiving the notification.

### Server-side: spread notification delivery

When dispatching a campaign, spread push notification delivery over a time window rather than sending to all subscribers simultaneously. Most push notification platforms support scheduled or throttled delivery.

### Client-side: add a random delay on receipt

When your application receives a push notification, do not make API calls immediately. Add a short random delay — for example, between 0 and 60 seconds — before initiating any API request triggered by the notification. This spreads the resulting load across a time window even if all notifications are delivered at the same instant.

> ❗️ A push campaign sent to 50,000 devices that immediately triggers one API call per device produces 50,000 near-simultaneous requests. This can resemble a denial-of-service attack and will activate rate limiting across the project.

---

## 10. API compatibility

CareCloud API may be extended at any time with new optional fields in request or response bodies. This is a backward-compatible change — your existing integration must not break when it encounters a field it does not recognise.

- Parse only the fields your application needs. Silently ignore any unknown fields.
- Do not validate responses against a hard-coded schema that rejects extra fields.
- When a new field is relevant to your use case, review the API reference and implement support for it in a planned update.

> 📘 The API version (`v1.0`) only increments on breaking changes. New optional fields within the same version do not require a version increment.

---

## 11. Logging and monitoring

Log every API call your application makes:

- Endpoint and HTTP method
- Response status code
- Response time (in milliseconds)

For non-2xx responses, log the full request and response body. Mask or omit personally identifiable information — email addresses, phone numbers, card numbers — before writing to logs.

Use your logs to:

- Diagnose errors during development and in production
- Identify endpoints that respond slowly and may benefit from caching
- Monitor request volume and spot unexpected spikes before they become incidents
- Understand usage patterns and plan optimisation work

> 👍 Structured logging (JSON format) makes it easier to search and aggregate log entries. Include a correlation ID or request ID in every log entry so you can trace a single user action through multiple API calls.

---

## 12. Follow the documented use cases

CareCloud provides tested, end-to-end use cases for common integration scenarios. Before designing a new integration flow, check the use case documentation — the correct sequence of API calls for scenarios such as customer registration, purchase recording, or customer login is already specified.

Implementing a use case out of sequence — for example, recording a purchase before the customer account exists — will fail with errors that could have been avoided.

Use case guides:

- [Build an e-shop integration](https://www.crmcarecloud.com/build-and-e-shop/)
- [Build a mobile application](https://www.crmcarecloud.com/build-a-mobile-app/)

SDKs and development tools: [Tools](https://carecloud.readme.io/reference/tools)

---

## Summary: server-side integrations (POS, e-commerce, backend systems)

**Use the enterprise interface.** It is designed for server-side systems that manage or process customer data. See [Enterprise interface authentication](https://carecloud.readme.io/reference/authentication#enterprise-interface-http-bearer-authentication).

**Keep credentials on the server.** Enterprise credentials and Bearer tokens must never leave a secured server environment. They must not appear in mobile app binaries, browser JavaScript, configuration files committed to a repository, or any medium accessible to end users.

**Handle token expiry.** Enterprise tokens expire after 7 hours by default. Implement a re-authentication flow that triggers when an HTTP `401` response is received. See [section 2](#2-authentication-and-token-security).

**Push campaign management.** If your system dispatches push notifications to customers, spread delivery over a time window rather than sending all at once. See [section 9](#9-push-notification-campaigns).

**Rate limit awareness.** Background jobs that synchronise or bulk-process data are the most common source of HTTP `429` errors. Implement a request queue with a configurable rate limiter. See [section 7](#7-handle-rate-limiting-http-429).

---

## Summary: client-side applications (mobile apps, web portals, kiosks, smart devices)

**Use the customer interface.** It is designed for applications that operate on behalf of a single customer and does not require enterprise credentials. See [Customer interface authentication](https://carecloud.readme.io/reference/authentication#customer-interface-http-bearer-authentication).

**Never include enterprise credentials.** Do not embed enterprise usernames, passwords, or Bearer tokens in a mobile app binary, browser bundle, or kiosk configuration file. Any user with access to the device can extract them.

**Secure token storage.** Store the device token in platform-provided secure storage: iOS Keychain, Android Keystore, or the browser Credential Management API. Do not store tokens in plain text files, `localStorage`, or URL parameters.

**Debounce every user action.** Accidental double-taps are common on mobile and kiosk devices. Disable interactive elements after the first press until a response is received. See [section 6](#6-user-action-debouncing).

**Manage push notification triggers.** If your application makes API calls in response to push notifications, add a random delay before initiating the request. See [section 9](#9-push-notification-campaigns).

**Plan for offline and slow connections.** Mobile devices can lose connectivity during a request. Configure read timeouts and handle the resulting error state gracefully. See [section 8](#8-handle-errors-and-service-unavailability).
