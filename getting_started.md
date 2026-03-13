CareCloud API allows you to create and manage customer accounts and related resources like countries, languages, currencies, sources, or customer account statuses. You can use the API to manage vouchers, rewards, customer cards, segments, and other structures related to the customer account.

Learn about the CareCloud API, which systems can use the API to connect with CDP CareCloud. Like e-shops, POS, kiosks, booking, and other production systems. These systems usually process the customer data sets with their relationships or end-user applications like mobile Android and iOS APPs or web microsites that need unique customer data.

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

#### (query_parameters)

All query parameters are documented and described with every resource. CareCloud API uses query parameters for pagination, filtration, or sorting of the API call results.

### Request body

CareCloud API has a request body in [JSON format](https://www.json.org/json-en.html).  
The request body is used in case of creating a new record, updating an existing record, or in the action method call. In the request body, CareCloud API works with two kinds of parameters described below.

#### Read-only parameters

These parameters are used only in response to API calls and should not be set in the request body of the API call. Please avoid using them during the create, update, or action method call.

#### Mandatory parameters

If a parameter is marked as `required` in the documentation, it is mandatory to use it in the CareCloud API call.

If a parent structure of the parameter is not mandatory and you won't use it, child parameters of that structure won't be required. If you use the parent structure in the API call, all child parameters marked as mandatory will be required. Every data structure parameter is marked in the documentation, so you can see if the parameter is mandatory or not.

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

## HTTPS Verbs

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
| 204 No Content      | In case of success without any response data |

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

### List or all error reasons from general API endpoints

[block:html]
{
"html": "<p>When an HTTP 400 error occurs, the response includes the parameter <code>reason</code>, which specifies the type of problem identified in the API request structure.</p>\n<table>\n  <thead>\n    <tr>\n      <th>status</th>\n      <th>exception</th>\n      <th>reason</th>\n      <th>description</th>\n    </tr>\n  </thead>\n  <tbody>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>already_exists</td>\n      <td>The value already exists in CareCloud. For example, creating a customer with an email address that is already registered.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>empty</td>\n      <td>A parameter value is expected but not provided in the request. For example, a missing <code>customer_id</code> value.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>not_found</td>\n      <td>The request contains a non-existing resource ID, but the API expects an existing one.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>required</td>\n      <td>A required parameter is missing from the request.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>not_allowed_value</td>\n      <td>The request contains a value that is not allowed for the parameter according to the API specification.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>invalid_value_format</td>\n      <td>The parameter value does not match the required format defined in the API specification.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>relation_already_exists</td>\n      <td>The request attempts to create a parameter combination that already exists in CareCloud and must be unique.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>not_belong_to_logged_in_customer</td>\n      <td>The parameter value does not belong to the currently logged-in customer. This prevents unauthorized data access.</td>\n    </tr>\n    <tr>\n      <td>400</td>\n      <td>bad_request_exception</td>          \n      <td>deleted</td>\n      <td>The request tries to access or modify a resource that has already been deleted.</td>\n    </tr>\n  </tbody>\n</table>"
}
[/block]


### Specific error messages for the purchase closure process

[block:html]
{
"html": "<p>Examples of the most occurred extended error codes from purchases resource endpoints and action methods:</p>\n      <table>\n        <thead>\n          <tr>\n            <th>status code</th>\n            <th>exception</th>\n            <th>name</th>\n            <th>reason</th>\n          </tr>\n        </thead>\n        <tbody>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>store_id</td>\n            <td>not_found</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>purchase_type_id</td>\n            <td>not_allowed_value</td>\n          </tr> \n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>bill_item_id</td>\n            <td>item_price_lower_than_paid_amount</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>bill_id</td>\n            <td>already_exists</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>bill_item_id</td>\n            <td>required</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>payment_time</td>\n            <td>invalid_value_format</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>credit_points</td>\n            <td>not_enough_points_for_payment</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>max_number_of_voucher_exceeded</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>system_id</td>\n            <td>different_system_id</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_not_allowed_in_store</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>not_enough_items_for_voucher</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_condition_count_not_satisfied</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_bonus_count_not_satisfied</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>unauthorized_use_vouchers</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>not_enough_items_for_voucher</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>not_enough_points_for_voucher</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_cant_be_applied_by_date</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_cant_be_applied_by_time</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_cant_be_applied_by_validity_days</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_cant_be_applied_by_segment</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_cant_be_used_in_store</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_assigned_to_another_customer</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_already_used</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_already_applied</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_expired</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>insufficient_amount_of_purchase</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_invalid_type_of_usage</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>card_number</td>\n            <td>card_is_blocked</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>benefit_codes</td>\n            <td>voucher_invalid_type_of_usage</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>max_points</td>\n            <td>points_min_amount_of_purchase</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>max_points</td>\n            <td>customer_cant_pay_by_points</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>payment_type</td>\n            <td>customer_cant_pay_by_credits</td>\n          </tr>\n          <tr>\n            <td>400</td>\n            <td>bad_request_exception</td>\n            <td>customer_id</td>\n            <td>customer_was_deleted</td>\n          </tr>\n        </tbody>\n      </table>\n      \n      <table>\n        <thead>\n          <tr>\n            <th>status code</th>\n            <th>exception</th>\n            <th>parameter</th>\n            <th>object_of_parameter</th>\n          </tr>\n        </thead>\n        <tbody>\n          <tr>\n            <td>400</td>\n            <td>missing_argument_exception</td>\n            <td>code</td>\n            <td>PluId</td>\n          </tr>\n        </tbody>\n      </table>\n      \n      <table>\n        <thead>\n          <tr>\n            <th>status code</th>\n            <th>exception</th>\n            <th>expected_type</th>\n            <th>actual_type</th>\n            <th>parameter</th>\n          </tr>\n        </thead>\n        <tbody>\n          <tr>\n           <td>400</td>\n           <td>invalid_argument_exception</td>\n           <td>string</td>\n           <td>null</td>\n           <td>payment_type</td>\n         </tr>\n        </tbody>\n      </table>\n      "
}
[/block]


<br />

## Action methods

We use procedural calls in CareCloud API when resolving logic in CareCloud. For example, making product recommendations or recommending the best reward for customers depending on the purchase. We call them Action methods. The Action method can be called by existing resources, as in the example below:

> 📘 POST  <https://{project_domain}/webservice/rest-api/{interface}/{version}/{resource_name}/actions/{action_method_name}>

Where `{resource_name}` represents a resource. The keyword `actions` identify the procedural call, and `{action_method_name}` is a unique name for the action. Action name is unique across the CareCloud API.

This is the example of the action “add customer” by resource segments:

`POST  https://{project_domain}/webservice/rest-api/enterprise-interface/v1.0/segments/{segment_id}/actions/add-customer`