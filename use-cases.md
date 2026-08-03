This page documents step-by-step API workflows for common integration scenarios. Each use case lists the API calls in the order they should be made, with links to the full endpoint documentation in the API reference.

Each use case is labelled with the interface it applies to:

| Label | Interface | Typical systems |
| --- | --- | --- |
| Customer interface | `customer-interface` | Mobile applications, web portals, kiosks, smart devices |
| Enterprise interface | `enterprise-interface` | POS, e-commerce backends, BI tools, backend data processing |

For details on authentication for each interface, see [Authentication](https://carecloud.readme.io/reference/authentication).

---

## Customer account management

### Customer sign-up

> 📘 **Interface:** Customer interface, Enterprise interface

1. To sign up a customer, collect all necessary customer information first. This may require calling other CareCloud API resources before creating a customer account with [POST /customers](https://carecloud.readme.io/reference/postcustomer).
2. For example, to get all available options for `store_id`, call [GET /stores](https://carecloud.readme.io/reference/getstores). The response contains a list of stores and their unique identifiers.
3. Use these values in the sign-up form so the customer can select the correct store. Save the selected value for the [POST /customers](https://carecloud.readme.io/reference/postcustomer) request.
4. Determine which customer source to assign to the customer. A customer source identifies the origin of the customer, for example, `e-shop` (registered through an e-shop) or `brick-and-mortar` (registered in a physical store). Each customer source record can include an external ID that represents the customer's identifier in the originating system. You can later search for customers by this external ID to synchronize data between systems. Call [GET /customer-sources](https://carecloud.readme.io/reference/getcustomersources) to retrieve the available customer sources. Select the one that fits and include the external ID in the customer creation request.
5. Customer properties can be set directly in [POST /customers](https://carecloud.readme.io/reference/postcustomer) or afterward using [POST /customers/{customer_id}/property-records](https://carecloud.readme.io/reference/postsubcustomerproperties). A list of all available properties is at [GET /customer-properties](https://carecloud.readme.io/reference/getcustomerproperties).
6. Call [POST /customers](https://carecloud.readme.io/reference/postcustomer) to create the customer account. Set `store_id` as the registration branch and `customer_source_id` as the source of the customer registration.
7. If you need to associate additional data with the customer account (such as interests, additional properties, or cards), call the corresponding POST endpoints for each resource.

### Customer credentials verification

> 📘 **Interface:** Enterprise interface

This use case applies to e-shop integrations where the application uses the enterprise interface to access a customer's data and needs to verify the customer's identity through a login screen before displaying it.

We recommend the following verification flow:

1. Display a sign-in form to the customer with fields for a customer identifier and a password.
   1. You can let the customer choose the identifier type (email or card number) before entering the value.
   2. Alternatively, you can present a single input field and determine the identifier type in your application before sending the API request (for example, using a regular expression to distinguish an email address from a card number). This simplifies the form for the customer while your application resolves the correct `login_type` value.
2. Validate the inputs on the client side (email format, card number format, password format) and display an appropriate error message to the customer if any input is invalid.
3. If all inputs are valid, send the credentials to the CareCloud API using the [POST /customers/actions/verify-credentials](https://carecloud.readme.io/reference/postcustomerverifycredentials) endpoint. The request requires three fields: `login_type` (card or email), `login_value`, and `password`.
4. Handle the API response:
   1. If the verification is successful, the API returns a customer ID. Use this ID to retrieve the customer's data from other CareCloud API endpoints, such as purchases, reservations, loyalty information, or personal data.
   2. If the verification fails, the API returns an error message describing the reason. Display an appropriate message to the customer in your application.
5. CareCloud API does not manage customer login sessions. The verify-credentials endpoint only confirms that the provided credentials are valid. After successful verification, your application is responsible for establishing and managing the customer's login session.

> ❗️ This use case cannot be applied using the customer interface. The endpoints used in this flow are available only in the enterprise interface.

### Search customers and get customer personal data

> 📘 **Interface:** Enterprise interface

This use case applies to e-shop or production system integrations where you need to access data of multiple customers or search for a customer by their identifiers (email, phone number, or name).

We recommend searching for customer data in the following way:

1. If you need to search for one or multiple customers, use [GET /customers](https://carecloud.readme.io/reference/getcustomers). To find customers, you need to know their email, phone number, first name, last name, or birth date.
2. Add these values as query parameters. The more parameters you provide, the more precise the results will be. This method can return multiple results if the parameter value is general, such as `name=John`.
3. The response contains customer information, including the customer ID, personal data, and consent settings, which you can process as needed.
4. If you want to search for one specific customer and expect exactly one result, use the action method [GET /customers/actions/search-customers](https://carecloud.readme.io/reference/getcustomersearch).
5. Set the `mode` query parameter to `strict`. In strict mode, all query parameters become required: first name, last name, birth date, and card number.
6. If CareCloud finds a matching customer, the response contains the customer ID.
7. To access the full customer data, call [GET /customers/{customer_id}](https://carecloud.readme.io/reference/getcustomer) with the customer ID from the previous step as a path parameter.
8. All methods above return responses containing the customer ID. You can use this ID as a path parameter in other resources to retrieve data linked to the customer, for example: [GET /customers/{customer_id}/vouchers](https://carecloud.readme.io/reference/getsubcustomervouchers), [GET /customers/{customer_id}/cards](https://carecloud.readme.io/reference/getsubcustomercards), or [GET /customers/{customer_id}/property-records](https://carecloud.readme.io/reference/getsubcustomerproperties). The full list of available sub-resources is in the [Customers](https://carecloud.readme.io/reference/getcustomers) section of the API reference.

### Find a customer by production system identification

> 📘 **Interface:** Enterprise interface

This use case applies when you need to find a customer using an identifier from an external system (other than CareCloud).

1. To find a customer by an external ID, the customer must have been created with a customer source record containing that ID. You can set this during customer creation at [POST /customers](https://carecloud.readme.io/reference/postcustomer) using the customer source parameter.
2. You can also add a customer source to an existing customer using [POST /customers/{customer_id}/customer-source-records](https://carecloud.readme.io/reference/postsubcustomersource).
3. If all customers have an identifier from your system, you can search for the customer source record by the external ID using [GET /customer-source-records](https://carecloud.readme.io/reference/getcustomersourcerecords). Include the external ID and the customer source identifier from CareCloud in the request.
4. If the customer source record exists, the response contains the customer ID.
5. Use the customer ID for subsequent API calls, for example, to retrieve customer data with [GET /customers/{customer_id}](https://carecloud.readme.io/reference/getcustomer) or to update the customer with [PUT /customers/{customer_id}](https://carecloud.readme.io/reference/putcustomer).

### Synchronize customers between production systems and CareCloud

> 📘 **Interface:** Enterprise interface

This use case describes synchronizing customer data between CareCloud and other systems (e-shop, POS, ERP, accounting systems, and others).

1. Try to find the customer in CareCloud using a customer ID from your system. Search for the customer source record with that ID using [GET /customer-source-records](https://carecloud.readme.io/reference/getcustomersourcerecords). Include the external ID and the customer source identifier from CareCloud in the request.
2. If the customer source record exists, the response contains the customer ID. You can then retrieve the existing customer information and synchronize it in your system using [GET /customers/{customer_id}](https://carecloud.readme.io/reference/getcustomer), or update the existing customer in CareCloud using [PUT /customers/{customer_id}](https://carecloud.readme.io/reference/putcustomer).
3. If the customer source record does not exist, create the customer using [POST /customers](https://carecloud.readme.io/reference/postcustomer) with the appropriate identification and customer source.
4. This use case works only if you synchronize external identifiers from the start. Otherwise, duplicate customer records may occur.

### Get customer personal data (customer interface)

> 📘 **Interface:** Customer interface

This use case applies to mobile applications or customer portal integrations where you need to access the logged-in customer's data.

We recommend accessing customer data in the following way:

1. The customer must be logged in before accessing their data. If you need to know how to log in a customer, see the [Log in and log out customer](#log-in-and-log-out-customer) use case.
2. To access the personal data of the customer, use [GET /customers](https://carecloud.readme.io/reference/getcustomers).
3. You do not need to add any path or query parameters. CareCloud API returns information about the logged-in customer automatically.
4. The response contains customer information, including the customer ID, personal data, and consent settings, which you can process as needed.
5. To access the customer's extended data, such as properties, use [GET /customers/property-records](https://carecloud.readme.io/reference/getsubcustomerproperties).

### Log in and log out customer

> 📘 **Interface:** Customer interface

This use case applies to mobile applications or customer portal integrations where you need to log in to a customer account to access personal information or other data.

This process requires the device to have an application token to access the CareCloud API. Instructions for obtaining and using application tokens are available in the [Authentication section](https://carecloud.readme.io/reference/authentication#customer-interface-http-bearer-authentication).

We recommend the following login process:

1. Collect the customer's login credentials and password through your application's login screen. Credentials are verified on the CareCloud servers, so your application does not need to store the customer's login and password.
2. After the customer submits the form, validate the login credentials (typically an email address) and password against the requirements described in the CareCloud API documentation.
3. After successful validation, call the login action method [POST /tokens/{token_id}/actions/login](https://carecloud.readme.io/reference/posttokenlogin).
4. If an error is returned, handle it according to the error message.
5. If the login is successful, the API returns the customer identifier.
6. When the customer is logged in, you can call most CareCloud API resources without specifying the customer ID. For example, information about the logged-in customer is available at [GET /customers](https://carecloud.readme.io/reference/getcustomers) without providing the customer ID. CareCloud recognizes the customer and returns their information.
7. Call [POST /tokens/{token_id}/actions/logout](https://carecloud.readme.io/reference/posttokenlogout) if the customer requests a logout.
8. After logging out, the application can only call resources available without a logged-in customer.
9. There are only two ways to log out a customer: calling the logout method, or the application token expiring. You can read more about application tokens in the [Authentication section](https://carecloud.readme.io/reference/authentication#customer-interface-http-bearer-authentication).

### Customer personal data update (customer interface)

> 📘 **Interface:** Customer interface

Updating a customer is a critical process. It is important to follow the correct procedure to preserve the customer's data.

1. Before updating, you need the customer's current data. If you do not store all customer data in your system, retrieve it with [GET /customers](https://carecloud.readme.io/reference/getcustomers). The response contains all customer data.
2. Modify the data as needed and update with [PUT /customers](https://carecloud.readme.io/reference/putcustomer). This endpoint must contain all customer information, because the PUT method replaces the entire resource. All parameters that are not included in the request will be deleted from the record, as defined by the [HTTP PUT verb](https://www.rfc-editor.org/rfc/rfc9110.html#name-put).
3. A successful update returns HTTP status code 204. If an error occurs, the error message explains the issue.
4. If you need to update customer properties, use [PUT /customers/property-records/{property_record_id}](https://carecloud.readme.io/reference/putsubcustomerproperty).

### Customer personal data update (enterprise interface)

> 📘 **Interface:** Enterprise interface

Updating a customer is a critical process. It is important to follow the correct procedure to preserve all customer data.

1. You need the customer's ID before updating. The ID can be obtained in multiple ways described in other use cases: [Search customers and get customer personal data](#search-customers-and-get-customer-personal-data), [Find a customer by production system identification](#find-a-customer-by-production-system-identification), or after [Customer credentials verification](#customer-credentials-verification). Make sure you retrieve the complete customer data with [GET /customers/{customer_id}](https://carecloud.readme.io/reference/getcustomer) before making the update call.
2. Update the customer's data with [PUT /customers/{customer_id}](https://carecloud.readme.io/reference/putcustomer). This endpoint must contain all customer information. All parameters that are not included in the request will be deleted from the record, as defined by the [HTTP PUT verb](https://www.rfc-editor.org/rfc/rfc9110.html#name-put).
3. A successful update returns HTTP status code 204. If an error occurs, the error message explains the issue.
4. If you need to update customer properties, use [PUT /customers/{customer_id}/property-records/{property_record_id}](https://carecloud.readme.io/reference/putsubcustomerproperty).

### Forgotten password (customer interface)

> 📘 **Interface:** Customer interface

This use case applies to mobile application or customer portal integrations where a customer needs to reset their password in CareCloud.

We recommend the following password reset flow:

1. The customer requests a password change because they do not remember their current password. All passwords are securely stored and protected on the CareCloud servers, so the application does not need to store passwords, which reduces the risk of data leaks.
2. The customer fills in their contact information (email, phone number, or other contact types if the project allows it) in the form. The application validates the contact format.
3. The application sends a request to the CareCloud action method [POST /tokens/{token_id}/actions/send-password-setup-email](https://carecloud.readme.io/reference/posttokensendpasswordsetup).
4. CareCloud validates the contact and checks its existence in the customer database. If the contact is found, CareCloud sends a message with a link to change the password. The message template can be configured by CareCloud administrators in the Campaigns and Segmentation section of the CareCloud platform.
5. The customer opens the message and clicks the link.
6. The customer is redirected to the password change form in CareCloud.
7. The customer fills out the form with a new password. The application validates the password against the character requirements.
8. After successfully changing the password, the customer is redirected based on the customer source assigned to their account. The redirect URL can be configured in the customer source administration in CareCloud.

### Forgotten password (enterprise interface)

> 📘 **Interface:** Enterprise interface

This use case applies to e-shop or production system integrations where a customer needs to reset their password in CareCloud.

We recommend the following password reset flow:

1. The customer requests a password change because they do not remember their current password.
2. The customer fills in their email address in the application form. The application validates the email address format.
3. After validation, the application checks whether the email address exists in CareCloud by calling [GET /customers](https://carecloud.readme.io/reference/getcustomers). If the email address is found, the application sends an email with a link to change the password.
4. The customer opens the email and clicks the link.
5. The customer is redirected to the application form for password change.
6. The customer fills out the form with a new password. The application validates the password against the character requirements defined in the CareCloud API (see the password field in [PUT /customers/{customer_id}](https://carecloud.readme.io/reference/putcustomer)).
7. After successful validation, the application updates the password in the customer's account by calling [PUT /customers/{customer_id}](https://carecloud.readme.io/reference/putcustomer) with the new password.
8. If successful, the application shows a success message and redirects the customer to the login form.

---

## Cards

### Assign a card to an existing customer

> 📘 **Interface:** Enterprise interface

This use case describes the process of assigning existing cards to a customer. It applies when the customer has a physical card and knows the card number. It covers only cards that already exist in the database and are ready to be assigned.

1. Find the card by its number. Search using the `card_number` query parameter in [GET /cards](https://carecloud.readme.io/reference/getcards).
2. If the card is found, check its parameters to confirm it is available. The `customer_id` parameter must have the value `null`, which means the card is not assigned to another customer.
3. Assign the customer to the card by calling [PUT /cards/{card_id}](https://carecloud.readme.io/reference/putcard). Set the `customer_id` parameter to the customer's ID. All other parameters remain unchanged.
4. After a successful API call, the card is assigned to the customer and ready to be used. If an error occurs, follow the error message to find the solution.

### Create a new card in CareCloud

> 📘 **Interface:** Enterprise interface

If you do not have pre-generated card numbers but you already have cards physically printed, this use case helps you insert a new card into CareCloud.

You can do this through the API. Alternatively, you can import cards manually through the CDP administration and then use the [Assign a card to an existing customer](#assign-a-card-to-an-existing-customer) use case.

1. If you choose the API approach, you first need to know the card type. All available card types are listed at [GET /card-types](https://carecloud.readme.io/reference/getcardtypes).
2. With the card type, card number, and customer ID, you can create a new card using [POST /cards](https://carecloud.readme.io/reference/postcard).
3. If everything is correct, the response contains the new card ID.
4. If an error occurs, follow the error message to find the solution.

---

## Newsletter

### Newsletter sign-up

> 📘 **Interface:** Customer interface, Enterprise interface

CDP CareCloud creates a customer account if one does not exist and adds a customer source dedicated to newsletters. This use case covers both existing customers and new customers.

A customer source identifies the origin of the customer (email, Facebook, registration, campaign). It tells you what the source of sign-up or registration is. Customers can have multiple customer sources.

1. Decide which customer source to use for the newsletter sign-up. A list of available customer sources is at [GET /customer-sources](https://carecloud.readme.io/reference/getcustomersources).
2. If you want to create a new customer source record for an existing customer, use [POST /customers/{customer_id}/customer-source-records](https://carecloud.readme.io/reference/postsubcustomersource).
3. When you have all the necessary data, call the action method [POST /customers/actions/newsletters-sign-up](https://carecloud.readme.io/reference/postcustomernewsletterssignup). The method creates a customer if the customer does not exist, sets all consents passed in the request, and assigns the specified customer source.

If a customer has already signed up for the newsletter and later wants to register a full account, follow the [Customer sign-up](#customer-sign-up) use case. CDP CareCloud handles this situation automatically.

---

## Marketing automation

### Create a marketing automation event

> 📘 **Interface:** Customer interface, Enterprise interface

Marketing automation events are used to launch a scenario connected to an event. The scenario covers any available automation in the CareCloud platform.

Marketing automation events have the following structure of resources:

- **Event group:** Groups divide event types into administrator-defined categories. An administrator can add, edit, or delete event groups from the administration environment of the CareCloud platform.
- **Event type:** A general definition of an event. Administrators can define event types that describe the behavior and structure of individual events.
- **Event properties:** A list of properties defined with the event type. Properties extend the event type with additional data fields.
- **Event:** A resource that allows you to create an event for a specific customer. The event starts a Marketing Automation scenario and can transfer data to the scenario, which the scenario can use to make decisions during its run.
- **Event property record:** Contains property values connected with an event.

#### Create an event

1. Before creating an event, identify which event type you want to use. Make sure it is correctly configured and includes all necessary properties. If you need to create a new event group, event type, or property, do so in the events section of the CareCloud administration.
2. To select an event type, you can filter by event group. List all event groups with [GET /event-groups](https://carecloud.readme.io/reference/geteventgroups).
3. Based on the results, select an event type that fits your event group or use other criteria from [GET /event-types](https://carecloud.readme.io/reference/geteventtypes).
4. If you need to set event properties, check the available properties at [GET /event-properties](https://carecloud.readme.io/reference/geteventproperties).
5. Create the event for a specific customer using [POST /events](https://carecloud.readme.io/reference/postevent). Property records are included directly in the event creation request so that all data is available to the Marketing Automation scenario immediately when it starts.

### Abandoned cart

> 📘 **Interface:** Customer interface, Enterprise interface

If you want to inform a customer about their abandoned cart, you can trigger a scenario in the Marketing Automation application by following the [Create a marketing automation event](#create-a-marketing-automation-event) use case.

There are two options for handling abandoned carts:

1. Your application or e-shop determines when the cart becomes abandoned. After that, it creates a marketing automation event.
2. If you cannot make the abandoned cart determination on the e-shop side, you can create a marketing automation event every time the shopping cart is updated and determine whether the cart is abandoned directly in the Marketing Automation scenario in CareCloud.

---

## Checkout process

> ❗️ Before starting the checkout process, make sure you have synchronized your product lists and product groups. See [Synchronize products, product groups, and product brands](#synchronize-products-product-groups-and-product-brands).

### Application of benefits in the shopping cart

> 📘 **Interface:** Enterprise interface

This use case applies to an e-shop or POS where a customer wants to use their benefits (rewards, discounts, coupons, or vouchers). This use case describes only the benefit application part. Other parts of the checkout process, such as [sending the final purchase](#send-purchase-simple-checkout) or [identifying the customer](#search-customers-and-get-customer-personal-data), are covered in separate use cases.

To apply benefits correctly, follow these steps:

1. Send the current content of the customer's shopping cart and any voucher codes (in the `benefit_codes` parameter) through [POST /purchases/actions/accept-payment](https://carecloud.readme.io/reference/postpurchaseacceptpayment). Make sure to set all necessary parameters, including `payment_type` and others as described in the API reference. Different types of benefits may be applied depending on the configuration.
2. The CareCloud API returns all applicable benefits for the shopping cart, the number of loyalty points that would be gained from the purchase, and the total customer loyalty points after the purchase. If the response does not contain any rewards or discounts, the algorithm found no applicable benefit for the customer.
3. Keep all the information from the CareCloud API response.
4. If the customer changes the shopping cart content, repeat the request to [POST /purchases/actions/accept-payment](https://carecloud.readme.io/reference/postpurchaseacceptpayment) with the updated shopping cart data. The response may differ because the customer might now fulfill certain conditions (product quantity thresholds, spending thresholds, or others).

### Loyalty points payment

> 📘 **Interface:** Enterprise interface

This use case allows you to use loyalty points for payments. The POS, e-shop, or other system can process point payments when a customer has available points in their account.

1. First, identify the customer. You can find the customer using the methods described in [Search customers and get customer personal data](#search-customers-and-get-customer-personal-data) or [Find a customer by production system identification](#find-a-customer-by-production-system-identification).
2. After identifying the customer, check their point balance to determine whether they have enough points to cover the purchase. The available points are at [GET /wallet/actions/points-overview](https://carecloud.readme.io/reference/getwalletpoints).
3. Depending on the number of available points, send the number of points to use along with all purchase items in the request to [POST /purchases/actions/accept-payment](https://carecloud.readme.io/reference/postpurchaseacceptpayment).
4. The CareCloud API responds with a list of recommended benefits and discounts and information about the number of points that can be used with that transaction.
5. Retain the information about the points used and reduce the final purchase price accordingly. Both values will be used in the following request to [POST /purchases/actions/send-purchase](https://carecloud.readme.io/reference/postpurchasesend).
6. If the customer wants to modify the shopping cart, you can update the [POST /purchases/actions/accept-payment](https://carecloud.readme.io/reference/postpurchaseacceptpayment) request and repeat it multiple times before sending the final purchase with [POST /purchases/actions/send-purchase](https://carecloud.readme.io/reference/postpurchasesend).

### Credit payment

> 📘 **Interface:** Enterprise interface

This use case allows you to use credits for payments. The POS, e-shop, or other system can process credit payments when a customer has available credits in their account.

1. First, identify the customer. You can find the customer using the methods described in [Search customers and get customer personal data](#search-customers-and-get-customer-personal-data) or [Find a customer by production system identification](#find-a-customer-by-production-system-identification).
2. After identifying the customer, check their credit balance to determine whether they have enough credit to cover the purchase. The available credits are at [GET /wallet/actions/credits-overview](https://carecloud.readme.io/reference/getwalletcredits).
3. Depending on the available credit and the customer's decision on how much credit to use, send the amount of credit to use along with all purchase items in the request to [POST /purchases/actions/accept-payment](https://carecloud.readme.io/reference/postpurchaseacceptpayment). For credit payments, use the appropriate `payment_type` (type `C`; for details, see the `payment_type` parameter in the [API reference](https://carecloud.readme.io/reference/postpurchaseacceptpayment)).
4. The CareCloud API responds with a list of recommended benefits and discounts and information about the credit that can be used with that transaction.
5. Retain the information about the credit used and reduce the final purchase price accordingly. Both values will be used in the following request to [POST /purchases/actions/send-purchase](https://carecloud.readme.io/reference/postpurchasesend).
6. If the customer wants to modify the shopping cart, you can update the [POST /purchases/actions/accept-payment](https://carecloud.readme.io/reference/postpurchaseacceptpayment) request and repeat it multiple times before sending the final purchase with [POST /purchases/actions/send-purchase](https://carecloud.readme.io/reference/postpurchasesend).

### Send purchase (simple checkout)

> 📘 **Interface:** Enterprise interface

This use case describes the process when the POS, e-shop, or other system needs to send a paid purchase or order to CareCloud. All benefits and discounts have been applied (or not), and the system is ready to finalize the transaction.

1. Before the transaction, ensure your system has synchronized products, product groups, and brands with CareCloud. Depending on your setup, synchronization may be necessary every time your product catalogue changes.
2. To send the purchase, use [POST /purchases/actions/send-purchase](https://carecloud.readme.io/reference/postpurchasesend).
3. Ensure all necessary parameters are set and the values match the current purchase: reduce the price based on any points or credits used, apply all benefits returned from the CareCloud API in previous steps (if applicable), and set the `payment_type` parameter appropriately for the type of transaction.
4. If successful, the CareCloud API returns the purchase ID.

### Cancel purchase

> 📘 **Interface:** Enterprise interface

If you need to cancel a purchase already sent to CareCloud, follow these steps:

1. To cancel a purchase or an order, use the same endpoint used for sending purchases: [POST /purchases/actions/send-purchase](https://carecloud.readme.io/reference/postpurchasesend).
2. Almost all parameters must be the same as in the original purchase. The only changes are: set `canceled` to `true`, use a unique value for `bill_id`, and set `bill_number` to the `bill_id` from the original purchase or order.

### Synchronize products, product groups, and product brands

> 📘 **Interface:** Enterprise interface

This use case describes how to synchronize products from POS, e-shop, or other production systems into CareCloud. We recommend completing this synchronization before you start applying rewards and discounts or sending purchases.

1. If you use product brands, synchronize them first with [POST /product-brands/batch](https://carecloud.readme.io/reference/postbulkproductbrands). This endpoint allows you to add multiple product brands in one request. If you have more than 1000 records, consider splitting the request into smaller batches.
2. Synchronize product groups using [POST /product-groups/batch](https://carecloud.readme.io/reference/postbulkproductgroups). The batch method allows you to synchronize multiple product groups in a tree structure where you can define parent groups if needed.
3. Synchronize products using [POST /products/batch](https://carecloud.readme.io/reference/postbulkproducts). In this endpoint, you can synchronize multiple products and associate them with their brands and product groups.
4. We recommend synchronizing brands, groups, and products whenever a new entity appears in your system or when an existing one changes. As with brands, consider the number of records in each request for all endpoints.
5. To avoid problems during synchronization, maintain the following order:
   1. Product brands
   2. Product groups
   3. Products
