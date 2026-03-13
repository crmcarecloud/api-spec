The CareCloud REST API lets you read and write customer data, manage loyalty programs, process transactions, and trigger marketing automation - all from your own applications.

The API is served through two distinct interfaces, each designed for a different integration context. Choose the one that matches your use case:

- **[Enterprise interface](#enterprise-interface)** - for backend systems, POS integrations, e-commerce platforms, and business intelligence tools.
- **[Customer interface](#customer-interface)** - for mobile applications, web portals, kiosks, and smart device applications.

Follow the guide for your interface below to make your first API call.

# Enterprise interface

Use this guide if you are building a POS system, an e-commerce backend, or a business intelligence integration.

## Before you start

You need the following before making your first API call:

- **Project URL** - the domain of your CareCloud installation (for example, `sandbox.crmcarecloud.com`)
- **External application ID** - provided by your CareCloud administrator
- **API user credentials** - a username and password for an API user with the `webservice` user group, provided by your CareCloud administrator

> 📘 If you do not have direct access to CareCloud, contact the responsible person in your organisation to provide these values.

## Step 1: Get a Bearer token

Call <a href="https://carecloud.readme.io/reference/postuserlogin" target="_blank">POST /users/actions/login</a> to authenticate and receive a Bearer token. No `Authorization` header is required for this request.

```http User login request
POST https://sandbox.crmcarecloud.com/webservice/rest-api/enterprise-interface/v1.0/users/actions/login
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8

{
  "user_external_application_id": "89d1a6111b3fb6e74665d948",
  "login": "fabulous_user",
  "password": "password_example"
}
```

The response includes a `bearer_token` value. Copy it - you will use it in every subsequent request.

```json User login response body
{
  "data": {
    "bearer_token": "09359095c5da43c7ae11e710eabce49418715a6a",
    "valid_to": "2023-01-04 10:31:56",
    "user": {
      "user_id": "838b73aacb5ac326cec4030c80",
      "login": "fabulous_user",
      "first_name": "Fabulous",
      "last_name": "Legend",
      "email": "fabulous_user@crmcarecloud.com",
      "phone": 420123828931,
      "user_role_id": "86e05affc7a7befcd513ab400",
      "store_id": "86e05affc7a7abecd513ab400"
    }
  }
}
```

## Step 2: Make your first API call

Add the `bearer_token` value to the `Authorization` header and call `GET /customers`.

```http request
GET https://sandbox.crmcarecloud.com/webservice/rest-api/enterprise-interface/v1.0/customers
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Bearer 09359095c5da43c7ae11e710eabce49418715a6a
```

A successful response returns a list of customers and the total number of matching records:

```json Response body
{
  "data": {
    "customers": [
      {
        "customer_id": "8ea6abece4cd0a4ded0a29f093",
        "personal_information": {
          "gender": 1,
          "first_name": "John",
          "last_name": "Smith",
          "birthdate": "985-02-12",
          "email": "happy_customer@crmcarecloud.com",
          "phone": "420523828931",
          "language_id": "en",
          "store_id": "8bed991c68a4",
          "address": {
            "address1": "Old Town Square",
            "address2": "34",
            "address3": "",
            "address4": "",
            "address5": "",
            "address6": "",
            "address7": "",
            "zip": "11000",
            "city": "Prague 1",
            "country_code": "cz"
          },
          "agreement": {
            "agreement_gtc": 1,
            "agreement_profiling": 1,
            "agreement_marketing_communication": 1,
            "custom_agreements": [
              {
                "agreement_id": "89ce2a1b9b01f5c939fb1e20cd",
                "agreement_value": 2
              }
            ]
          }
        },
        "last_change": "2019-06-23 11:47:22",
        "state": 1
      }
    ],
    "total_items": 1
  }
}
```

## Step 3: What to do next

- **API overview** - for general and detailed information about the API, see the <a href="https://carecloud.readme.io/reference/getting-started-with-your-api" target="_blank">API overview</a>.
- **Token validity and re-authentication** - tokens expire after 7 hours by default. For details on expiry handling and re-authentication, see <a href="https://carecloud.readme.io/reference/authentication#enterprise-interface-http-bearer-authentication" target="_blank">Enterprise interface authentication</a>.
- **Production integration guidance** - before deploying, review the <a href="https://carecloud.readme.io/reference/best-practices" target="_blank">Integration best practices</a> page.
- **Tools** - to explore the API interactively before writing code, import the Postman collection or use the SDK. See <a href="https://carecloud.readme.io/reference/tools" target="_blank">Tools</a>.
- **Integration use cases** - to see what you can build with the Enterprise interface, browse the <a href="https://www.crmcarecloud.com/build-and-e-shop/#use-cases" target="_blank">integration use cases</a>.

---

# Customer interface

Use this guide if you are building a mobile application, a web portal, a kiosk, or a smart device application.

## Before you start

You need the following before making your first API call:

- **Project URL** - the domain of your CareCloud installation (for example, `sandbox.crmcarecloud.com`)
- **External application ID** - provided by your CareCloud administrator

> 📘 If you do not have direct access to CareCloud, contact the responsible person in your organisation to provide these values.

## Step 1: Create a device token

Call <a href="https://carecloud.readme.io/reference/posttoken" target="_blank">POST /tokens</a> to create an access token for your application installation. This request does not require an `Authorization` header.

```http request
POST https://sandbox.crmcarecloud.com/webservice/rest-api/customer-interface/v1.0/tokens
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8

{
  "device": {
    "device_id": "123456",
    "device_system": "OSX",
    "device_name": "Test device",
    "device_type": "iPhone"
  },
  "setup": {
    "language_id": "en",
    "allowed_gps": true,
    "allowed_notifications": false
  },
  "external_application_id": "81eaeea13b8984a169c490a325"
}
```

The response returns a `token_id`. This value is your Bearer token for all subsequent requests.

```json Response body
{
  "data": {
    "token_id": "4d8121dea8ae3c7b7fc66e6924ecc466dc7aa13e299ac757d87533ab2630f31bd906aadf"
  }
}
```

## Step 2: Log in as a customer (optional)

> 📘 Skip this step if your application does not need customer-specific data. The device token alone is sufficient for endpoints that do not require a logged-in customer.

Call <a href="https://carecloud.readme.io/reference/posttokenlogin" target="_blank">POST /tokens/{token_id}/actions/login</a> to associate the token with a customer account. Use the `token_id` from step 1 in both the URL path and the `Authorization` header.

```http Customer login request
POST https://sandbox.crmcarecloud.com/webservice/rest-api/customer-interface/v1.0/tokens/4d8121dea8ae3c7b7fc66e6924ecc466dc7aa13e299ac757d87533ab2630f31bd906aadf/actions/login
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Bearer 4d8121dea8ae3c7b7fc66e6924ecc466dc7aa13e299ac757d87533ab2630f31bd906aadf

{
  "login_type": "email",
  "login_value": "example@crmcarecloud.com",
  "password": "password_example"
}
```

The response returns the `customer_id` of the authenticated customer:

```json Response body
{
  "data": {
    "customer_id": "8ea6abece4cd0a4ded0a29f093"
  }
}
```

## Step 3: Make your first API call

Add the `token_id` value to the `Authorization` header and call `GET /customers`.

```http request
GET https://sandbox.crmcarecloud.com/webservice/rest-api/customer-interface/v1.0/customers
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Bearer 4d8121dea8ae3c7b7fc66e6924ecc466dc7aa13e299ac757d87533ab2630f31bd906aadf
```

A successful response returns the customer record for the logged-in customer:

```json Response body
{
  "data": {
    "customers": [
      {
        "customer_id": "8ea6abece4cd0a4ded0a29f093",
        "personal_information": {
          "gender": 1,
          "first_name": "John",
          "last_name": "Smith",
          "birthdate": "985-02-12",
          "email": "happy_customer@crmcarecloud.com",
          "phone": "420523828931",
          "language_id": "en",
          "store_id": "8bed991c68a4",
          "address": {
            "address1": "Old Town Square",
            "address2": "34",
            "address3": "",
            "address4": "",
            "address5": "",
            "address6": "",
            "address7": "",
            "zip": "11000",
            "city": "Prague 1",
            "country_code": "cz"
          },
          "agreement": {
            "agreement_gtc": 1,
            "agreement_profiling": 1,
            "agreement_marketing_communication": 1,
            "custom_agreements": [
              {
                "agreement_id": "89ce2a1b9b01f5c939fb1e20cd",
                "agreement_value": 2
              }
            ]
          }
        },
        "last_change": "2019-06-23 11:47:22",
        "state": 1
      }
    ],
    "total_items": 1
  }
}
```

## Step 4: What to do next

- **API overview** - for general and detailed information about the API, see the <a href="https://carecloud.readme.io/reference/getting-started-with-your-api" target="_blank">API overview</a>.
- **Token behaviour and device identifier requirements** - for details on token lifecycle and how `device_id` affects token validity, see <a href="https://carecloud.readme.io/reference/authentication#customer-interface-http-bearer-authentication" target="_blank">Customer interface authentication</a>.
- **Production integration guidance** - before deploying, review the <a href="https://carecloud.readme.io/reference/best-practices" target="_blank">Integration best practices</a> page.
- **Tools** - to explore the API interactively before writing code, import the Postman collection or use the SDK. See <a href="https://carecloud.readme.io/reference/tools" target="_blank">Tools</a>.
- **Integration use cases** - to see what you can build with the Customer interface, browse the <a href="https://www.crmcarecloud.com/build-a-mobile-app/#use-cases" target="_blank">integration use cases</a>.
