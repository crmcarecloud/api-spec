CareCloud API is a REST API for integrating external systems with the CDP CareCloud platform. It provides endpoints for managing customer accounts and related structures, including loyalty cards, vouchers, rewards, points, credits, and reference data such as countries, languages, currencies, and customer statuses.

The API is used by two types of integration: backend systems such as e-commerce platforms, point-of-sale systems, kiosks, and booking platforms that process and synchronise customer data; and end-user applications such as mobile applications and web microsites that provide customers with access to their own account data.

## Just getting started?

Check out our <a href="https://carecloud.readme.io/reference/quickstart" target="_blank">quick-start guide</a> to make your first API call.

## CareCloud API call structure

### URI syntax

CareCloud API URI is assembled from multiple parts that are described in the example below:

> 📘 <https://{project_domain}/webservice/rest-api/{interface}/{version}/{resource_name}/{resource_id}?{query_parameters}>

#### {project_domain}

The domain of your CDP CareCloud installation. In the Reference guide, we use <https://sandbox.crmcarecloud.com>. You will get your project domain after confirming your CDP CareCloud plan.

#### {interface}

The interface describes what kind of data access your application will have. In CareCloud API we use two kinds of interface:

- Enterprise interface (URL part: `enterprise-interface`)
  It is mainly created for e-shops, POS, kiosks, booking, and other similar production systems that need to get the data lists.

- Customer interface (URL part: `customer-interface`)
  It is created and used mainly for end-user applications like mobile Android and iOS APPs or web customer microsites needing unique customer data.

We have created and described two API interfaces, where the main difference is the purpose of the systems for which the API is created.

#### {version}

It represents the versioning of the CareCloud API. CareCloud API uses the following format:

`vX.Y`

- `X` represents a number of the major versions. The major version number increases when significant changes or improvements are made. Usually, these changes are not backward-compatible with the previous version.
- `Y` represents a number of the minor versions. The minor version number increases when minor features or bug fixes are applied. These changes should be backward-compatible with the previous version.

The current versions of CareCloud API are available in the Reference guide.

#### {resource_name}

This URL part represents the name of the resource you need to get data from. The API reference guide shows the complete list of resources and endpoints.

#### {resource_id}

A resource ID is used when you need to identify an accurate resource record. For example, while getting, updating, or deleting this record.

#### {query_parameters}

All query parameters are documented and described with every resource. CareCloud API uses query parameters for pagination, filtration, or sorting of the API call results.

### Request body

CareCloud API has a request body in [JSON format](https://www.json.org/json-en.html).
The request body is used in case of creating a new record, updating an existing record, or in the action method call. In the request body, CareCloud API works with two kinds of parameters described below.

#### Read-only parameters

These parameters are used only in response to API calls and should not be set in the request body of the API call. Please avoid using them during the create, update, or action method call.

#### Mandatory parameters

If a parameter is marked as `required` in the documentation, it is mandatory to use it in the CareCloud API call.

If a parent structure of the parameter is not mandatory and you won't use it, child parameters of that structure won't be required. If you use the parent structure in the API call, all child parameters marked as mandatory will be required. Every data structure parameter is marked in the documentation, so you can see if the parameter is mandatory or not.

### Response format

Every API response uses `Content-Type: application/json`. All response payloads are wrapped in a top-level `data` object. List responses also include a `total_items` field at the root of `data`, which represents the total count of matching records across all pages (not just the current page). Example:

```json
{
  "data": {
    "customers": [ ... ],
    "total_items": 342
  }
}
```

### Pagination and sorting

All list endpoints support pagination via two query parameters:

| Parameter | Default | Description |
| --- | --- | --- |
| `count` | 100 | Number of records to return per page (minimum: 1) |
| `offset` | 0 | Number of records to skip before the first returned record |

Use `total_items` from the response to determine whether additional pages exist.

Sorting is supported via:

| Parameter | Values | Description |
| --- | --- | --- |
| `sort_field` | Any first-level response field name | Field to sort by |
| `sort_direction` | `ASC`, `DESC` | Sort order |

All parameters are optional. Supported parameters for each endpoint are listed in the API reference for that endpoint.

### HTTP headers

HTTP headers are an essential part of CareCloud API calls. They are used for language setup, authentication, or content identification.

#### Request headers

Headers you need to configure before sending a request to the CareCloud API.

##### Accept-Language

It is used when the integrator needs to set the language of the response (for example name, description, or note parameters). For more information, please check [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html#name-accept-language).

```HTTP header
Accept-Language: cs, en-gb;q=0.8
```

##### Content-Type

It indicates the media type of the request body. In CareCloud API, we require content type `application/json`. For more information about Content-Type please check [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html#field.content-type).

```HTTP header
Content-Type: application/json
```

##### Authorization

This header is used for the resources that require authentication. Our authentication method is Bearer and you can find out more in the [Authentication section](https://carecloud.readme.io/reference/authentication).

```HTTP header
Authorization: Bearer VDFBBAME577QVRSRTRLC93CNBGJYTRA4
```

#### Response headers

You will receive the headers in the response from the CareCloud API.

##### Cache-Control

Every endpoint in CareCloud API could be cached. If this is the case, you can find the Cache-Control header in the response from CareCloud API call. The header will contain information on how long the received data will be cached until refresh. The information  is stored in `max-age` parameter and the value is in seconds. If you do not receive the Cache-Control header, the cache was not applied to your API call.

## API Endpoint Caching

CareCloud API supports caching of endpoint responses to improve performance and reduce server load. However, whether a specific endpoint's response is cached and for how long depends on your project's configuration.

### Enable or modify caching for an endpoint

To use caching in the API, please contact your CareCloud administrators. They can configure caching settings for your project.

### To determine if an API response is cached

Check the `Cache-Control` HTTP header. This header provides information about caching directives, including the `max-age` directive, which specifies the maximum time (in seconds) that the response can be cached. If you do not receive the `Cache-Control` header, the cache was not applied to your API call.

```Text HTTP header
Cache-Control: max-age=3600
```

In this example, the response can be cached for up to 3600 seconds (1 hour).

### Note

Caching can impact data freshness. If you require real-time data, consider disabling caching for specific endpoints or consult with your CareCloud administrator.

## HTTP verbs

CareCloud API is available only through the secure protocol HTTPS. CareCloud API supports the following selection of HTTP verbs:

### GET verb

Make a `GET` request to retrieve data depending on URI and query string.

Read more about GET here: [RFC9110](https://www.rfc-editor.org/rfc/rfc9110.html#name-get)

### POST verb

`POST` is used to create new resource/resources, and CareCloud API uses the POST verb for action methods calls.

Read more about POST here: [RFC9110](https://www.rfc-editor.org/rfc/rfc9110.html#name-post)

### PUT verb

`PUT` method updates an entire resource record specified by its unique ID.

> ❗️ Be Careful if you use the PUT method. You must update the entire resource record because you are updating the origin representation. Parameters that you skipped will be deleted in that record.

Read more about PUT here: [RFC9110](https://www.rfc-editor.org/rfc/rfc9110.html#name-put)

### DELETE verb

Use the `DELETE` verb to remove a resource specified by the unique ID. This verb is used only by some resources. Read more here: [RFC9110](https://www.rfc-editor.org/rfc/rfc9110.html#name-delete)

## Status codes

Status codes represent the status of the API response.

| Success status code | Description                                  |
| ------------------- | -------------------------------------------- |
| 200 OK              | Successful                                   |
| 201 Created         | Resource was created                         |
| 204 No Content      | Successful response with no content returned |

| Error status code         | Description                                                                                               |
| ------------------------- | --------------------------------------------------------------------------------------------------------- |
| 400 Bad Request           | Bad input parameter. Error message specifies the detail                                                   |
| 401 Unauthorized          | The client has invalid credentials or an auth token                                                       |
| 403 Forbidden             | The client does not exist, or the client tried to access non-authorized property/resource                 |
| 404 Not Found             | The resource was not found                                                                                |
| 405 Method Not Allowed    | The resource does not support the specified HTTP method                                                   |
| 429 Too Many Requests     | Too many requests - more than the resource limit                                                          |
| 500 Internal Server Error | The server is not working as expected                                                                     |
| 503 Service Unavailable   | Temporary state when the service is temporarily unavailable, overloaded, or there is a maintenance window |

### List of all error reasons from general API endpoints

When an HTTP 400 error occurs, the response includes the parameter `reason`, which specifies the type of problem identified in the API request structure.

| status | exception | reason | description |
| --- | --- | --- | --- |
| 400 | bad_request_exception | already_exists | The value already exists in CareCloud. For example, creating a customer with an email address that is already registered. |
| 400 | bad_request_exception | empty | A parameter value is expected but not provided in the request. For example, a missing `customer_id` value. |
| 400 | bad_request_exception | not_found | The request contains a non-existing resource ID, but the API expects an existing one. |
| 400 | bad_request_exception | required | A required parameter is missing from the request. |
| 400 | bad_request_exception | not_allowed_value | The request contains a value that is not allowed for the parameter according to the API specification. |
| 400 | bad_request_exception | invalid_value_format | The parameter value does not match the required format defined in the API specification. |
| 400 | bad_request_exception | relation_already_exists | The request attempts to create a parameter combination that already exists in CareCloud and must be unique. |
| 400 | bad_request_exception | not_belong_to_logged_in_customer | The parameter value does not belong to the currently logged-in customer. This prevents unauthorized data access. |
| 400 | bad_request_exception | deleted | The request tries to access or modify a resource that has already been deleted. |

### Specific error messages for the purchase closure process

Examples of the most occurred extended error codes from purchases resource endpoints and action methods:

| status code | exception | name | reason |
| --- | --- | --- | --- |
| 400 | bad_request_exception | store_id | not_found |
| 400 | bad_request_exception | purchase_type_id | not_allowed_value |
| 400 | bad_request_exception | bill_item_id | item_price_lower_than_paid_amount |
| 400 | bad_request_exception | bill_id | already_exists |
| 400 | bad_request_exception | bill_item_id | required |
| 400 | bad_request_exception | payment_time | invalid_value_format |
| 400 | bad_request_exception | credit_points | not_enough_points_for_payment |
| 400 | bad_request_exception | benefit_codes | max_number_of_voucher_exceeded |
| 400 | bad_request_exception | system_id | different_system_id |
| 400 | bad_request_exception | benefit_codes | voucher_not_allowed_in_store |
| 400 | bad_request_exception | benefit_codes | not_enough_items_for_voucher |
| 400 | bad_request_exception | benefit_codes | voucher_condition_count_not_satisfied |
| 400 | bad_request_exception | benefit_codes | voucher_bonus_count_not_satisfied |
| 400 | bad_request_exception | benefit_codes | unauthorized_use_vouchers |
| 400 | bad_request_exception | benefit_codes | not_enough_items_for_voucher |
| 400 | bad_request_exception | benefit_codes | not_enough_points_for_voucher |
| 400 | bad_request_exception | benefit_codes | voucher_cant_be_applied_by_date |
| 400 | bad_request_exception | benefit_codes | voucher_cant_be_applied_by_time |
| 400 | bad_request_exception | benefit_codes | voucher_cant_be_applied_by_validity_days |
| 400 | bad_request_exception | benefit_codes | voucher_cant_be_applied_by_segment |
| 400 | bad_request_exception | benefit_codes | voucher_cant_be_used_in_store |
| 400 | bad_request_exception | benefit_codes | voucher_assigned_to_another_customer |
| 400 | bad_request_exception | benefit_codes | voucher_already_used |
| 400 | bad_request_exception | benefit_codes | voucher_already_applied |
| 400 | bad_request_exception | benefit_codes | voucher_expired |
| 400 | bad_request_exception | benefit_codes | insufficient_amount_of_purchase |
| 400 | bad_request_exception | benefit_codes | voucher_invalid_type_of_usage |
| 400 | bad_request_exception | card_number | card_is_blocked |
| 400 | bad_request_exception | benefit_codes | voucher_invalid_type_of_usage |
| 400 | bad_request_exception | max_points | points_min_amount_of_purchase |
| 400 | bad_request_exception | max_points | customer_cant_pay_by_points |
| 400 | bad_request_exception | payment_type | customer_cant_pay_by_credits |
| 400 | bad_request_exception | customer_id | customer_was_deleted |

| status code | exception | parameter | object_of_parameter |
| --- | --- | --- | --- |
| 400 | missing_argument_exception | code | PluId |

| status code | exception | expected_type | actual_type | parameter |
| --- | --- | --- | --- | --- |
| 400 | invalid_argument_exception | string | null | payment_type |

## Rate limiting

CareCloud API enforces request rate limits. When a client exceeds the configured limit, the API returns HTTP `429 Too Many Requests`. Retrying immediately after a `429` response will continue to fail. Use an exponential backoff strategy before retrying. See the [Integration best practices](https://carecloud.readme.io/reference/integration-best-practices) guide for a detailed approach.

## Action methods

CareCloud API uses procedural calls to resolve logic within the platform, such as making product recommendations or determining the best reward for a customer based on a purchase. These are called action methods.

Action methods follow one of two URI patterns, depending on whether the action applies to a specific record or to the resource as a whole:

**Resource-level action** - applies to the resource without targeting a specific record:

> 📘 POST  <https://{project_domain}/webservice/rest-api/{interface}/{version}/{resource_name}/actions/{action_method_name}>

**Record-level action** - applies to a specific record identified by `{resource_id}`:

> 📘 POST  <https://{project_domain}/webservice/rest-api/{interface}/{version}/{resource_name}/{resource_id}/actions/{action_method_name}>

The keyword `actions` identifies the procedural call, and `{action_method_name}` is a unique name for the action. Action names are unique across the CareCloud API.

This is an example of the record-level action "add customer" on the segments resource:

`POST  https://{project_domain}/webservice/rest-api/enterprise-interface/v1.0/segments/{segment_id}/actions/add-customer`
