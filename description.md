Learn here the basics of the Customer Data Platform CareCloud API, from authentication to usage of available resources. Learn about the CDP CareCloud REST API, which Systems can use API to connect with CDP CareCloud. Like e-shops, POS, kiosks, booking, and other similar production systems. These systems usually process the customer data sets with their relationships or end-user applications like mobile Android and iOS APPs or web microsites that need to get the unique customer data.

#### [Getting started](#section/Getting-started)

This is the description of the basics of the CDP CareCloud API. It is desribed here the [domain structure](#section/Getting-started/Domain-structure) and the parameters of the URL, the difference between  Enterprise  and  Customer API, [HTTP methods](#section/Getting-started/HTTPS-Methods) used in the API, [authentication details](#section/Authentication) and more.

#### [CRM CareCloud API Reference](#section/CRM-CareCloud-API-Reference)

[CRM CareCloud API Reference](#section/CRM-CareCloud-API-Reference) describes each available [Resource](#section/CRM-CareCloud-API-Reference/Available-resources-overview) in the API, you can learn more about parameters, errors, and how to format your requests. Review all available resources for CRM CareCloud REST API with this reference overview.

# Getting started

CRM CareCloud REST API allows you to create and manage the customer accounts and related resources like countries, languages, currencies, sources or customer account statuses. You can use the API for management of vouchers, rewards, customer cards, segments and other structures related to customer account.

## Domain structure

The domain structure is like  `<projectURL>`/customer-interface/v1.0/customers where  `<projectURL>`  corresponds to the specific URL of your project. For example for project of company called Cortex, the  `<projectURL>`  could be https://cortex.crmcarecloud.com/webservice/rest-api/ or local URL https://project.carecloud.cz/webservice/rest-api/ or any other similar URL. REST API is available only through secure protocol HTTPS.

We have created and described two API types, where the main difference is the authentication method and the purpose of the systems for which the API is created.

### Enterprise API

The  Enterprise interface client authenticates with login and password. The Enterprise API is mainly created for e-shops, POS, kiosks, booking and other similar production systems which needs to get the data lists.
The domain structure for Enterprise interface API is like  `<projectURL>`/enterprise-interface/v1.0/customers, where :

-   `<projectURL>`  the specific URL of your project
-   `enterprise-interface`  represents the type of API
-   `v1.0`  is the version of the API (this is only example, please the check actual version with your integration support)
-   `customers`  is an example of the resource. List of resources is available in  CRM CareCloud API Reference

### Customer API

The  Customer interface client authenticates  with user name and token. The Customer API is created and used mainly for end user applications like mobile Android and iOS APPs or web customer microsites which needs to get the unique customer data.
The domain structure for the Customer interface API is like  `<projectURL>`/customer-interface/v1.0/customers
Where :

-   `<projectURL>`  the specific URL of your project
-   `customer-interface`  represents the type of API
-   `v1.0`  is the version of the API (this is only example, please check the actual version with your integration support)
-   `customers`  is an example of the resource. List of resources is available in  CRM CareCloud API Reference

## API call parameters

Every API call has the following parameters:

-   Path - contains domain, version, resource, identifier of resource, subresource and the subresource unique id: https://project.crmcarecloud.com/webservice/rest-api/customer-interface/v1.0/resource-name/resource_id/actions/action_id
-   Query string - uses as filter for results, pagination and limitation of results
-   Request body - contains structures for methods POST, PUT
-   Response body - contains all result data (resources or error information) in  standard response structure

## HTTPS Methods

REST API is available only through the secure protocol HTTPS. CRM CareCloud REST API uses selection of the basic HTTP methods:

Make a `GET ` request to retrieve data depending on URI and query string

`POST ` is used to create new resources, we use it also for some action calls

`PUT` method is used to update a resource specified by the unique id

Method `DELETE` removes a resource specified by the unique id. This method is provided just by some specific resources.

## API versioning

Versioning of the API has the following pattern:
`<vX.Y>`
where:

-   X represents the major version. The major version serial number increases when an incompatible API changes are made.
-   Y represents the minor version. The minor version serial number increases when we add a functionality in a backwards-compatible manner

If developers fix issues in the API a changelog report is published. Changelog contains a version of the API, date and description of the fix.

## Actions

In special cases, if it is not possible to follow the RESTful way, we use the procedural call. We call it Action. It is possible the Action to be called by existing resources as in the example below.

POST  `<projectURL>`/customer-interface/v1.0/resource-name/resource_id/actions/action_id

Where ‘resource-name’ represents a resource with its unique id - resource_id. Keyword actions identifies an action call and action_id is a unique id of the action that is represented by name of the action. Action name is unique across the API.

This is the example of the action “add customer” by resource segments:

POST  `<projectURL>`/customer-interface/v1.0/segments/{segment_id}/actions/add-customer

## Status codes

Status codes represent a status of the API response.

| Success status code | Description |
| ----------- | ----------- |
| 200 OK | Successful |
| 201 Created | Resource was created |
| 204 No Content | In case of the success without any response data |

| Error status code | Description |
| ----------- | ----------- |
| 400 Bad Request | Bad input parameter. Error message specifies the detail |
| 401 Unauthorized | The client has invalid credentials or auth token |
| 403 Forbidden | The client does not exist or the client tried to access non authorized property/resource |
| 404 Not Found | The resource was not found |
| 405 Method Not Allowed | The resource does not support the specified HTTP method |
| 429 Too Many Requests | Too many requests - more than the resource limit |
| 500 Internal Server Error | Server is not working as expected |
| 503 Service Unavailable | Temporary state when the service is temporarily unavailable, overloaded or there is a maintenance window |

## Language version

It is used, when the integrator needs to get the right language version of the requested information (like name, description or note). To be able to identify the language version it is necessary to set HTTP header field accept-language.

```http request
GET / HTTP/1.1
Host: project.crmcarecloud.com
Accept-Language: cs
```

## Read-only parameters

These kinds of parameters are used only in response to API calls, and they should not be set in the request body of the API call. Please avoid using them during use POST or PUT HTTP method. Every data structure parameter is marked in documentation, so you can see if parameter is read only or not.

## Mandatory parameters

If a parameter is marked as mandatory in the documentation, it has to be used in API calls. If a parent structure is not mandatory and you won't use it, child parameters of that structure won't be required. If you use the parent structure in the API call, all child parameters that are marked as mandatory will be required. Every data structure parameter is marked in the documentation, so you can see if the parameter is mandatory or not.

# Authorization

<!-- ReDoc-Inject: <security-definitions> -->

# Use cases

## Authentication and login process for customer interface

1. Get `<user name>` from your account manager. It is usually `customer_interface` for the customer interface, but it might be different depending on the project.<br/>
2. Create a token using the method  [[POST] /tokens](#operation/postToken).
   The creation of a token is different from other API calls.  HTTP Authorization header contains only a login name and no token (because it doesn't exist yet).
```http request
<user name>:
 ```
Value of HTTP header Authentication contains BASE64 encoded string `<user name>:`. The request looks like this:

```http request
POST <projectURL>/rest-api/customer-interface/v1.0/tokens
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOiA=
```
3. You will get a token_id as a response.
```json
{
  "data":{
    "token_id":<token_id>
  }
}
```
4. The next step is to put together the user name and token in the HTTP Authorization header. The value of the header has to be BASE 64 encoded.
```http request
<user name>:<token_id>
```
HTTP Authorization header looks similar to:
```http request
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOiA=
```
5. For the customer login use the method [[POST] /tokens/{token_id}/actions/login](#operation/postTokenLogin). Remember to set `<token_id>` in the  HTTP Authorization header as is in step nr. 4. Put right customer credentials in the request's body after.

<p class="warning"> Note: Do not copy the credentials below. Code is just an example of a method used.</p>

```json
{
  "login_type": "email",
  "login_value": "example@crmcarecloud.com",
  "password": "password_example"
}
```
6. You will receive the customer_id of the logged-in customer as a response.
```json
{
  "data":{
    "customer_id":<customer_id>
  }
}
```

## Creation of a customer account process

1. You should know all the values for the required/optional customer account parameters before creating a customer account by [[POST] /customers](#operation/postCustomer). Use any available resource you need to get the lists of actual values. We will use resource stores in this example. To get all options for `store_id` you should call [[GET] /stores](#operation/getStores). Parameter `store_id` will be set during the customer account creation process.
```http request
GET <projectURL>/rest-api/customer-interface/v1.0/stores
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<token>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

2. You will get a response containing the list of stores and their unique IDs.
```json
{
   "data": {
      "stores": [
         {
            "store_id": "86e05affc7a7abefcd513ab400",
            "store_code": "",
            "name": "Great Pub",
            "store_address": {
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
            "contact_email": "",
            "manager_name": "",
            "phone_number": "",
            "partner_id": "86e05affc7a7abefcd513ab400",
            "system_id": 2375303497,
            "gps_coordinates": {
               "gps_longitude": 0,
               "gps_latitude": 0
            },
            "url_address": "",
            "opening": [ ],
            "image_urls": [ ],
            "visibility_for_customer": 1,
            "short_description": "fdsfdsfds",
            "description": null,
            "registration_id": 123,
            "last_change": "2018-12-19 16:12:56",
            "state": 1
         }
      ],
      "total_items": 1
   }
}
```

3. You will get a response containing the list of stores and their unique IDs.
   Use the method [[POST] /customers](#operation/postCustomer) to create a customer account and set `store_id` as the registration branch of a customer account.
   </br>Header:
```http request
POST <projectURL>/rest-api/customer-interface/v1.0/customers
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<token>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```
Request body:
```json
{
   "customer": {
      "personal_information": {
         "gender": 1,
         "first_name": "John",
         "last_name": "Smith",
         "birthdate": "985-02-12",
         "email": "happy_customer@crmcarecloud.com",
         "phone": 420523828931,
         "language_id": "en",
         "store_id": "8bed991c68a4",
         "photo_url": null,
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
                  "agreement_id": "custom_agreement_id",
                  "agreement_value": 2
               }
            ]
         }
      }
   },
   "customer_source": {
      "customer_source_id": "8fdce3475560d56e95a6ab035r",
      "external_id": null
   },
   "password": "password_example",
   "autologin": true,
   "social_network_credentials": {
      "social_network_id": "twitter",
      "social_network_token": "38e123j1jedu12d1jnjqwd"
   }
}
```

4. Set all the parameters according to the documentation and get a response including `customer_id`.
```json
{
    "data":{
        "customer_id":"89ac83ca207a820c62c79bf03a"
    }
}
```

5. Customers subresources can be set during the process of a customer account creation. Customer's interests and properties will be set in the next steps. Lists of all available interests and properties are available using the [[GET] /interests](#operation/getInterests) and [[GET] /customer-properties](#operation/getCustomerProperties).
6. To save a value of interest on a customer account use the interest-records subresource [[POST] /customers/{customer_id}/interest-records/](#operation/postSubCustomerInterest) as follows:
```http request
POST <projectURL>/rest-api/customer-interface/v1.0/customers/89ac83ca207a820c62c79bf03a/interst-records
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<token>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```
```json
{
   "interest_record": {
      "interest_id": "81eaeea13b8984a169c490a325",
      "customer_id": "89ac83ca207a820c62c79bf03a"
   }
}
```

6. You will get a response including the interest record unique id.
```json
{
   "data": {
      "interest_record_id": "87d934c86a6303f5fb4d1214fb"
   }
}
```

7. Use a similar process to set a property value on a customer account. Use subresource property-records [[POST] /customers/{customer_id}/property-records](#operation/postSubCustomerProperties) as follows:
```http request
POST <projectURL>/rest-api/customer-interface/v1.0/customers/89ac83ca207a820c62c79bf03a/property-records
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<token>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```
```json
{
   "property_record": {
      "property_id": "contact_person",
      "property_name": "Project contact person",
      "property_value": [ ]
   }
}
```

8. You will get a response with the property record id.
```json
{
   "data": {
      "property_record_id": "contact_person:8aa2049ac2f84952014d96bb23"
   }
}
```

9. Repeat POST method calls if you need to set more property-records or interest-records on a customer account.

## How to authenticate customers in external application

Use case covers authorization of a customer in an external application through REST API (customer interface only).
For more information, please look at the picture below:

<img src="img/login_between_two_apps_with_auth_token-3.png">

## How to create a Marketing Automation Event?

Marketing automation events are used to launch a scenario connected to an event. The scenario covers any available automation in CareCloud platform.

Marketing Automation Events has the following structure of resources:

<img src="https://imgur.com/0Bu8zWI.jpeg">

**Event group:** groups divide event types into administrator-defined categories. An administrator can add, edit or delete event groups from the administration environment of the CareCloud platform.

**Event type:** It is a general definition of an event. As an administrator, you can define event types that describe the behavior and structure of following events.

**Event properties:** It is a list of properties defined with the connected event type. It is a good way how to extend event type possibilities.

**Event:** It is a resource that allows you to create an event for a specific customer. The event starts a Marketing Automation scenario. It can transfer data to the scenario. Marketing automation scenarios can use the data to make better decisions during their run.

**Event property record:** It contains values of property that is connected with an event.

### Create an event

1. If you want to create an event through CareCloud REST API, make sure you know what type of event you wish to create. Correctly set it up, and check if it contains all necessary properties. If you need to create a new event group, you can do it in the events section of the CareCloud administration. You can also create a new event type or property there. When everything is set up in CareCloud administration, we can go to the next step.

2. First, you have to decide what event type you want to use to create an event. To help you decide, you might select an event type depends on the event group. List of the groups you can list with API call of resource [[GET] /event-groups](#operation/getEventGroups):

```http request
GET <projectURL>/rest-api/enterprise-interface/v1.0/event-groups
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<password>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

Depends on the results, you can select a list of event types that fits your event group or use other criteria from an [event-types resource documentation](#tag/Event-types):
```http request
GET <projectURL>/rest-api/enterprise-interface/v1.0/event-types?event_group_id=8bdf68d3838b4e009991
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<password>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

3. If you decided on an event type that fits your use case, you could check if you need to use any of the available [event properties](#tag/Event-properties):

```http request
GET <projectURL>/rest-api/enterprise-interface/v1.0/event-properties
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<password>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

4. Now is the time to create an event for a specific customer. Call the method [[POST] /events](#operation/postEvent) with parameters:

```http request
POST <projectURL>/rest-api/enterprise-interface/v1.0/events
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<password>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```
```json
{
   "event": {
      "event_type_id": "8bed991c68a470e7aaeffbf048",
      "customer_id": "81ceb8582e2d8dbb7e71b7273b",
      "external_id": 157613,
      "data": "{\"test\":10,\"test2\":20}",
      "created_at": "2017-06-20 16:59:49",
      "secondary_external_id": null
   },
   "property_records": [
      {
         "property_id": "contact_person",
         "property_name": "Project contact person",
         "property_value": [ ]
      }
   ]
}
```

5. As you can see, the creation of events also contains values of properties. You set property records in events resource because we need to have all data available for the MA scenario in one API call to start immediately after.
   If you want to see a list of events, call the method [[GET] /events](#operation/getEvents) with query params:

```http request
GET <projectURL>/rest-api/enterprise-interface/v1.0/events
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<password>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

6. If you need to see property values of the event, please call subresource of events - [[GET] /events/{event_id}/property-records](#operation/getSubEventProperties):

```http request
GET <projectURL>/rest-api/enterprise-interface/v1.0/events/85bc5819e09dab9/property-records
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<password>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

## Update of a forgotten password - customer

Use case covers update of customer's password through REST API. In this case, an external application operates the whole process and updates the customer's password after a new password confirmation.

<img src="img/forgotten_password_1.png">

Use case covers update of customer's password through REST API. It includes sending a forgotten password email to the customer.

<img src="img/forgotten_password_rest_api-send-fp-email.png">

## Use of the resource properties

1. Every resource in API has a list of parameters, that are static. As we know, every client has different requirements, and that's why we have additional properties structure in some of our resources. The additional properties contain list of a properties, that can be used by clients to set up a properties that are not used in the main parameters of a resource. The additional properties make API flexible to use.

2. Resource [[GET] /rewards](#operation/getRewards) contains an additional properties parameter. Additional properties have the same strutcure throughout the API.

3. API call of the resource [[GET] /rewards](#operation/getRewards) can show us all properties and the values of that resource:
```http request
POST <projectURL>/rest-api/customer-interface/v1.0/rewards
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
#<user name>:<token>
Authorization: Basic Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

4. You will get a response containing the list of rewards with all of their additional properties.

```json
"data": {
    "rewards": [
      {
        "reward_id": "8bdf68d3838b4e009991819e85",
        "code": "",
        "name": "Letní balíček 2017",
        "note": null,
          ...
      	"additional_properties": [
            {
            "property_record_id": "global:8bdf68d3838b4e009991819e85",
            "property_id": "global",
            "property_name": "Global setup of reward",
            "property_value": true,
            "last_change": "2017-06-14 10:43:49.882375"
          	}
       ],
        "priority": null,
        "image_urls": [],
        "last_change": "2017-06-14 10:43:49.882375",
        "state": 1
      },
       ...
```

## Assign a free card to the existing customer
This use case describes the process of assigning free cards to the existing customer. In this case, the customer holds the card and knows the number of the card. It covers only cards that exist in the database already, and they are ready to be used.

1. Find a free card that it could be assigned to the customer by the card number. To do that, you have to filter cards.
   Use parameters `card_number` to filter a card that the customer holds.

```http request
GET <projectURL>/webservice/rest-api/enterprise-interface/v1.0/cards?card_number=2001900627
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Bearer Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

```json
{
  "data": {
    "cards": [
      {
        "card_id": "8ecdd31720a5de8af85e1c566",
        "customer_id": null,
        "card_type_id": "86e05affc7a7abcd513ab400",
        "card_number": "2001900627",
        "state": 1,
        "valid_from": null,
        "valid_to": null,
        "store_id": null,
        "last_change": "2012-08-21 14:25:13.821752"
      }
    ],
    "total_items": 35415
  }
}
```
2. If you got a successful result, that means the card you are looking for exists in the database. The next step is to check the card's parameters to confirm it is free to use.
   You need to check parameter `customer_id` (should have value `null`) to filter only cards without a relation to the customer.

3. You need to add customer identification when you find a free card by parameters from the previous point.
   With the following API call from resource [PUT /cards](#operation/putCard).
   Set parameter `customer_id` like in example `e05affc7a7abefc513ab` with the customer id. Other parameters stay unchanged.

```http request
PUT <projectURL>/webservice/rest-api/enterprise-interface/v1.0/cards/8ecdd31720a5de8af85e1c566
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Bearer Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```
```json
{
    "card": 
      {
        "card_id": "8ecdd31720a5de8af85e1c566",
        "customer_id": "e05affc7a7abefc513ab",
        "card_type_id": "86e05affc7a7abcd513ab400",
        "card_number": "2001900627",
        "state": 1,
        "valid_from": null,
        "valid_to": null,
        "store_id": null,
      }
}

```

4. After the successful API call, the card has been assigned to the customer, and it's ready to be used.
   In case of any error, please follow the error message to find the solution.

5. If you didn't find any card, the card you were looking for is not in the system. In this case, you should insert a new card into the system.
   There is a way how to do it through API. Otherwise, you have to import cards manually to the system via CDP administration.
   If you decide to use an API solution, you can create a new card. For that, you need to know a card type.
   If you don't know card type, you can select a card type from the resource [GET /card-types](#operation/getCardTypes):

```http request
GET <projectURL>/webservice/rest-api/enterprise-interface/v1.0/card-types
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Bearer Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

Response:

```json
{
  "data": {
    "card_types": [
      {
        "card_type_id": "8bd48117006496e01788109b8",
        "name": "Business card",
        "prefix": "12"
      },
      {
        "card_type_id": "85d85ccae1fbb739f0a6db02b",
        "name": "REST API card type",
        "prefix": ""
      }
    ],
    "total_items": 2
  }
}
```

6. Now you know the card type, card number, and customer id. You can create a new card in the system.
   For that, you will use the resource [POST /cards](#operation/postCard).

```http request

POST <projectURL>/webservice/rest-api/enterprise-interface/v1.0/cards/
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Bearer Y3VzdG9tZXJfaW50ZXJmYWNlOmNlMzZjMDg2YmZjN2U3YjBkMjNjNjY3YjdhOTUxZTk=
```

```json
{
    "card": 
      {
        "customer_id": "e05affc7a7abefc513ab",
        "card_type_id": "8bd48117006496e01788109b8",
        "card_number": "2001900627",
        "state": 1,
        "valid_from": null,
        "valid_to": null,
        "store_id": null,
      }
}

```

7. If you have done everything right, you will get a card id in the response.

```json

{
  "data": {
    "customer_id": "82c973544d6279113f387bc"
  }
}
```
8. In case of any error, please follow the error message to find a solution.

# CRM CareCloud API Reference

CRM CareCloud API Reference describes each available resource in the API. Learn more about parameters, errors, and how to format your requests.  
Review all available resources for CRM CareCloud API with this reference overview. Learn the basics of the API in CRM CareCloud  [Documentation](#).

## Available resources overview

### [Campaign products](#tag/Campaign-products)

Campaign products are sets of products that are offered to Customers under special conditions, with different type of benefits. It can be used like a catalogue of discounted products on a special web site/e-shop or a set of special offers distributed to households as leaflet or direct mail. All this kind of campaign product types can be managed in CRM CareCloud directly or via CareCloud API.

### [Cards](#tag/Cards)

The Customer can be identified by different unique identificators - cards related to the account. Credit Card, Loyalty Card, mobile Card, skipass, virtual Card or any other type of unique personal ID or any other identification method like barcode, QR code or any other key can be used. All the unique customer cards (identificators) related to the Customer account can be processed by this resource.

### [Card types](#tag/Card-types)

Different card types can be managed in CRM CareCloud. Credit Card, Loyalty Card, mobile Card, skipass, virtual Card or any other type of unique personal ID or any other identification method like barcode, QR code or any other key can be used. The card types can be differenciated by a prefix, name or design and managed by this resource.

### [Countries](#tag/Countries)

Some data, especially addresses are tied to a Country, which is listed in CRM CareCloud. You can get here the list of countries available.

### [Customers](#tag/Customers)

CRM CareCloud like a Customer Relationship Management system is about 360 view on a Customer and all relationships of the uinque Customer. Resource Customers is used for creation, processing and managing this basic entity, which contains personal and all additional related information about the Customer.

### [Customer source](#tag/Customer-sources)

Customer account can be created and tied to different sources, like online registration form, e-shop, mobile app, POS, booking system, web microsite, campaign or any other source. This source is related to customer account and can be managed by this resource.

### [Currencies](#tag/Currencies)

Some data, especially Products can be tied to a Currency which is listed in CRM CareCloud. You can get here the list of currencies available.

### [Languages](#tag/Languages)

Some data, especially Customer accounts or Tokens are tied to a Language, which is listed in CRM CareCloud. You can get here the list of languages available.

### [Points](#tag/Points)

If there is a Loyalty program managed by CRM CareCloud based on points collection, the points collection and redemption can be managed by this resource.

### [Products](#tag/Products)

There is a Product database in CRM CareCloud that is available via this resource. Products are related to Product Groups, Product Brands and Stores. All this related information can be used for creation of Customer benefits tied to Products.

### [Product Brands](#tag/Product-brands)

There is a possibility to create sets of Products within the same brand, called Product Brands. Products are related to Product Groups, Product Brands and Stores. All this related information can be used for creation of Customer Benefits tied to Product Brands.

### [Product Groups](#tag/Product-groups)

There is a possibility to create sets of Products with similar properties, called Product Groups. Products are related to Product Groups, Product Brands and Stores. All this related information can be used for creation of Customer Benefits tied to Product Groups.

### [Product Reservations](#tag/Product-reservations)

CRM CareCloud allows to reserve Products or Product sets and manage the reservation process. There is the possibility to create a special group of Products that can be reserved - Reservable products. The Reservation of a Product can be created by this resource.

### [Reservable Products](#tag/Reservable-products)

The set of Products that could be reserved can be limited. We call this group Reservable Products. You can get the details of Reservable Products and search within this group by this resource.

### [Purchases](#tag/Purchases)

There are the purchases tied to customer accounts stored in CRM CareCloud. The purchases are saved online when closing the bill or imported by the offline web service after the purchase. There are many parameters that specifies the purchase like bill items and its prices, date and time of the purchase, store, where purchase was made or loyalty card number. All this data are used for segmentation or voucher creation.

### [Recommendations](#tag/Recommendations)

There is the possibility to recommend the customers a product, a service or just an information in CRM CareCloud based on customer purchasing behavior and many other criteria. All recommendations can be viewed by this resource.

### [Rewards](#tag/Rewards)

Different types of Rewards for Customers can be created and managed in CRM CareCloud. The Reward is a pattern for creation of individual customer Vouchers that can be applicated to the Customer purchases directly. It is defined by a set of parameters like Reward validity, prioroty or number of points, that will be spent by application and many other. You can create rewards and get the information about actual rewards processed in CRM CareCloud by this resource.

### [Segment](#tag/Segments)

Segments are customer groups, which can be defined and created in CRM CareCloud according to many different criteria. Customers in the Segment share some specific common information or property and can be managed via this resource.

### [Statuses](#tag/Statuses)

Status is a specific property of a customer account which can be achieved based on the defined criteria, like its validity, achieving principle or loyalty switch. It is often used for management of loyalty membership levels within the loyalty scheme setup and can be processed by this resource.

### [Stores](#tag/Stores)

You can manage the network of stores (company branches) via this resource. Many properties as address, GPS coordinates, opening hours or contact details can be synchronized with any other system.

### [Tokens](#tag/Tokens)

Management of token resources. Tokens are used for identification of the application installation on a device and for setup of basic application parameters (permissions, language, notification identification).

### [Vouchers](#tag/Vouchers)

Vouchers are generated by the Rewards for a specific Customer account and they are applied during the purchasing process. They are defined by its value, validity and related Reward. Vouchers can be managed by this resource.