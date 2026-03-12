The section will answer all your questions about using and integrating CareCloud API.

## What is the purpose of CareCloud API?

You can integrate the external applications with the CareCloud platform via the documented CareCloud API. The integration enables data exchange between the CareCloud platform and an integrated external application.

Through the CareCloud API, you can integrate applications designed for CareCloud platform users (POS and EPOS systems, e-shops, kiosks, BI, accounting systems, and more) or external applications designed for customers, i.e., mobile applications, customer portals, and customer microsites.

The CareCloud API documentation describes the unique data resources, explains their use through examples and use cases, and answers basic questions in the FAQ section.

## What interface is the best to use?

CareCloud API has two kinds of interfaces:

- customer interface
- enterprise interface

The best way to decide what interface to use is to look at the [following section](https://carecloud.readme.io/reference/getting-started-with-your-api#interface).

## What is an external application?

An external application is your identification for CareCloud API. It helps us to know which application uses REST API. Because as an integrator, you could integrate more applications to one installation of our CareCloud API.

You have to use `external_application_id` in multiple resources around CareCloud API. The External application is not a resource; you can find or create an ID for your application in CareCloud administration.

If you don't know how to find it, here is [a guide](https://carecloud.readme.io/reference/authentication#external-applications) to get, create or manage existing applications.

## What authentication is used for the REST API enterprise interface?

CareCloud API uses Bearer authentication if resources require it. You can find the complete guide in the [Authentication section](https://carecloud.readme.io/reference/authentication)

## How exactly does the PUT verb work in CareCloud REST API?

Just a friendly reminder, all our update methods use HTTP PUT. This HTTP verb updates the whole structure, so ensure you have all the necessary data to avoid losing any.  
HTTP PUT doesn't support updating a single parameter. You need to send the whole data set. For more information, read this [article](https://www.geeksforgeeks.org/difference-between-put-and-patch-request/).

## How do I create a customer account?

In the CareCloud platform, each customer has a customer account, to which all data related to this customer are assigned. The customer account can be found and identified by any unique identifier (such as a customer's email or phone number) associated with that account.  
You can create a customer account using the method [\[POST\] /customers](https://carecloud.readme.io/reference/postcustomer). We also created [a use case](https://www.crmcarecloud.com/build-and-e-shop/#accordion-enterprise-use-case-customer-account-operations-0) describing the whole process.

## How can I log in as a customer?

Customer login is not mandatory in CareCloud API for specific resources. If the customer wants to access their personal or purchase data, they must log in. How to do it is described in [the following use case section](https://www.crmcarecloud.com/build-a-mobile-app/).