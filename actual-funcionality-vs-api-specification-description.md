a# Actual functionality versus API specification description

Comparison of CareCloud REST API implementation against the OpenAPI specification.
Each finding describes a behavior that is either undocumented, deviates from standard REST conventions, or contradicts the specification.

This report is temporary and is not part of the git repository. After user confirmation, individual findings will be used to extend the specification descriptions.

## Methodology

Each finding was produced by reading the PHP controller code and comparing it against the corresponding OpenAPI specification file. All controller and service class references are relative to `~/projects/carecloud-repository/`.

**Controllers analyzed** (all under `modules/webservice/rest-api/classes/controllers/`):
CustomersResourceControllerV1v0, CardsResourceControllerV1v0, PurchasesResourceControllerV1v0, PointsResourceControllerV1v0, CreditsResourceControllerV1v0, CreditHistoryResourceControllerV1v0, RewardsResourceControllerV1v0, VouchersResourceControllerV1v0, OrdersResourceControllerV1v0, WalletResourceControllerV1v0, ProductsResourceControllerV1v0, ProductGroupsResourceControllerV1v0, ProductBrandsResourceControllerV1v0, ProductReservationsResourceControllerV1v0, ReservableProductsResourceControllerV1v0, ProductReservationPricesResourceControllerV1v0, StamperCampaignsResourceControllerV1v0, StamperCardsResourceControllerV1v0, StampsResourceControllerV1v0, SegmentsResourceControllerV1v0, SegmentRecordsResourceControllerV1v0, StatusesResourceControllerV1v0, StatusRecordsResourceControllerV1v0, EventsResourceControllerV1v0, EventTypesResourceControllerV1v0, EventGroupsResourceControllerV1v0, CampaignsResourceControllerV1v0, CampaignProductsResourceControllerV1v0, MessagesResourceControllerV1v0, MessageTemplatesResourceControllerV1v0, StoresResourceControllerV1v0, PartnersResourceControllerV1v0, PartnerRecordsResourceControllerV1v0, UsersResourceControllerV1v0, TasksResourceControllerV1v0, TokensResourceControllerV1v0, BookingsResourceControllerV1v0, BookingTicketsResourceControllerV1v0, OneTimePasswordResourceControllerV1v0, RecommendationEngineResourceControllerV1v0, ReferralsResourceControllerV1v0, RelatedCustomersResourceControllerV1v0, InterestRecordsResourceControllerV1v0, ExternalApplicationsResourceControllerV1v0, AudiencesResourceControllerV1v0, CustomerEngagementContainersResourceControllerV1V0

**Shared business logic**:
- `modules/system/classes/model/account/` (AccountInputOutputProcess, AccountRegistrationProcess, AccountEditProcess)
- `modules/crm/classes/interface/CrmInterfaceForWebservice.class.php`
- `modules/crm/classes/interface/CrmInterface.class.php`
- `modules/crm/classes/model/accounts/AccountsServices.class.php`
- `modules/crm/classes/model/credits/CreditsServices.class.php`
- `modules/crm/classes/model/vouchers/VouchersServices.class.php`
- `modules/crm/classes/model/segments/SegmentsServices.class.php`
- `modules/crm/classes/model/articles/ArticlesServices.class.php`
- `modules/crm/classes/model/product_reservations/ProductReservationsServices.class.php`
- `modules/ecs/classes/interface/EcsInterfaceForWebservice.class.php`
- `modules/crm/classes/iterator_factory/CrmInterfaceIteratorsFactory.class.php`

---

## Customers

### 1. POST /customers - Non-club account merge

**Endpoint**: `POST /customers`
**Specification file**: `paths/customers/Customers.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:1055`
**Business logic**: `AccountRegistrationProcess.class.php:59-68`

**What happens**: If the email address belongs to an existing non-club (non-loyalty) account, the system does not reject the registration as a duplicate. Instead, it reuses the existing account record and merges the input data into it. Fields that are null in the request are populated from the existing account's personal information (salutation, gender, first name, last name, phone, birthdate, address fields). The existing account is then upgraded to a club account.

**Why it matters**: An integrator sending a POST request would expect either a new account to be created or a duplicate error to be returned. The silent merge means the response contains a `customer_id` that may have pre-existing data, purchase history, and card associations from the previous non-club account. The integrator has no indication that a merge occurred.

**Recommendation**: Document the non-club merge behavior in the POST /customers description. Explain that if the email belongs to an existing non-club account, the account is reused and upgraded, input data is merged with existing data (with input values taking precedence over existing ones), and the returned `customer_id` refers to the pre-existing account.

---

### 2. POST /customers - Virtual card auto-assignment

**Endpoint**: `POST /customers`
**Specification file**: `paths/customers/Customers.yaml`
**Controller**: `AccountRegistrationProcess.class.php:167-182`

**What happens**: After account creation, a virtual card is automatically assigned to the customer. The assignment depends on project configuration: if a configuration parameter specifies which membership levels qualify for virtual card assignment, only customers with a matching membership level receive a card. If the configuration parameter is not set, all newly registered customers receive a virtual card. If no virtual card is available, the registration still succeeds but no card is assigned (the exception is caught and handled in `GeneralRestApiAccountRegistrationProcess.class.php:335`).

**Why it matters**: An integrator creating customers and separately managing card assignments may not expect a card to already be present. Subsequent card assignment logic could conflict with or duplicate the automatically assigned card.

**Recommendation**: Add a note to the POST /customers description that a virtual card may be assigned automatically based on project configuration and the customer's membership level. Note that unavailability of a virtual card does not cause the registration to fail.

---

### 3. POST /customers - Gender auto-detection from name

**Endpoint**: `POST /customers`
**Specification file**: `paths/customers/Customers.yaml`
**Controller**: `AccountInputOutputProcess.class.php:679-684`, `AccountsServices.class.php:1512-1525`

**What happens**: If the gender field is not set (null), the system attempts to infer the gender from the customer's first and last name using a gender identification service. If a gender is successfully inferred, it is set on the account automatically.

Additionally, gender values outside the valid range (1 through 5) are silently set to null before processing (`CustomersResourceControllerV1v0.class.php:1318-1329`), which then triggers the auto-detection.

**Why it matters**: An integrator who intentionally omits the gender field (expecting it to remain empty) may find a gender value set on the account when reading it back. The silent normalization of invalid values means the integrator receives no error feedback for out-of-range values.

**Recommendation**: Document in both POST and PUT descriptions that the gender field is auto-detected from the customer's name when not provided or when an invalid value is supplied. List the valid gender values (1 through 5) and state that any other value is treated as null.

---

### 4. POST /customers - Salutation auto-generation

**Endpoint**: `POST /customers`
**Specification file**: `paths/customers/Customers.yaml`
**Controller**: `AccountInputOutputProcess.class.php:686-688`, `AccountsServices.class.php:1616-1634`

**What happens**: If the salutation field is null or empty, the system generates a salutation automatically based on the customer's last name, gender, and communication language. The generated salutation always includes a trailing comma.

On subsequent updates, if the customer's gender or last name changes and the current salutation matches the previously auto-generated value, the salutation is regenerated to reflect the new name or gender (`AccountsServices.class.php:2128`).

**Why it matters**: An integrator who does not provide a salutation may not expect one to appear on the account. The regeneration on name or gender changes can overwrite what appears to be an untouched field. The trailing comma in the auto-generated salutation is a formatting convention that integrators should be aware of.

**Recommendation**: Document in both POST and PUT descriptions that the salutation is auto-generated from the last name, gender, and communication language when not provided. Mention that changing the gender or last name may cause the salutation to be regenerated if it matches the previously auto-generated value.

---

### 5. POST /customers - photo_url is rejected

**Endpoint**: `POST /customers`
**Specification file**: `paths/customers/Customers.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:590-594`

**What happens**: If `photo_url` is included in the request body, the endpoint always returns HTTP 400 with reason `not_allowed_value`. Photo uploads must be performed through a separate endpoint (`POST /customers/{customer_id}/actions/upload-photo`).

**Why it matters**: The `photo_url` field is present in the Customer schema (visible in the request body), which suggests it can be set. An integrator attempting to set it during registration receives a generic error with no guidance about the correct upload method.

**Recommendation**: Add a note to the `photo_url` field description in the Customer schema stating that it is read-only and cannot be set via POST or PUT. Reference the upload-photo action endpoint as the correct method.

---

### 6. POST /customers - Email address is lowercased

**Status**: Not important for integrators. Email lowercasing is standard behavior that any system performs. Integrators should not rely on case-sensitive email matching.

**Endpoint**: `POST /customers`
**Specification file**: `paths/customers/Customers.yaml`
**Controller**: `AccountInputOutputProcess.class.php:630-634`

**What happens**: Email addresses are automatically converted to lowercase and trimmed before saving. An email like `User@Example.COM` is stored as `user@example.com`.

**Why it matters**: While email lowercasing follows RFC 5321 (the local part is technically case-sensitive, but in practice most mail servers treat it as case-insensitive), integrators comparing stored email values against their own records using case-sensitive matching will find mismatches.

**Recommendation**: Document that email addresses are normalized to lowercase on both create and update operations.

---

### 7. PUT /customers - store_id is preserved when not provided

**Endpoint**: `PUT /customers/{customer_id}`
**Specification file**: `paths/customers/Customer.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:183`

**What happens**: When `store_id` is not provided (null) in the PUT request, the code preserves the existing store_id value on the account instead of clearing it. The implementation is: `$store_id === null ? $account->getIdstore() : $store_id`.

**Why it matters**: This deviates from standard PUT semantics, where omitting a field in the request body should reset it to its default (typically null or empty). An integrator who omits `store_id` expecting it to be cleared will find the previous value still in place. The specification already documents a similar exception for the `password` field but does not mention `store_id`.

**Recommendation**: Add `store_id` to the list of fields that do not follow standard PUT semantics. Document that omitting `store_id` preserves the existing value rather than clearing it.

---

### 8. PUT /customers - Updating a deleted customer returns 400, not 404

**Endpoint**: `PUT /customers/{customer_id}`
**Specification file**: `paths/customers/Customer.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:151-153`

**What happens**: If the target customer account is in a deleted state, the endpoint returns HTTP 400 with reason `deleted` and the message "Update of deleted customer is not possible." The customer ID is valid and the account exists in the database, but it is marked as deleted.

**Why it matters**: An integrator would typically expect a deleted resource to return HTTP 404 (Not Found) or HTTP 410 (Gone). Receiving HTTP 400 (Bad Request) for a deleted resource is non-standard and requires specific error handling logic.

**Recommendation**: Document that attempting to update a deleted customer returns HTTP 400 with reason `deleted`. Explain that deleted customers remain in the system but cannot be modified.

---

### 9. PUT /customers - Email collision triggers account merge

**Endpoint**: `PUT /customers/{customer_id}`
**Specification file**: `paths/customers/Customer.yaml`
**Controller**: `AccountEditProcess.class.php:243`

**What happens**: If the updated email address belongs to a different non-club (non-loyalty) account, the system merges the two accounts at the database level by handling the `DibiUniqueConstraintViolationException`. The non-club account's data is absorbed into the account being updated.

**Why it matters**: An integrator changing a customer's email address would expect either success (the email is unique) or an error (the email is already taken). A silent merge of accounts is unexpected and can have significant side effects on the merged account's data, purchase history, and card associations.

**Recommendation**: Document that changing a customer's email to one that belongs to a non-club account results in the accounts being merged. The non-club account is absorbed into the updated account.

---

### 10. PUT /customers - photo_url is rejected

**Endpoint**: `PUT /customers/{customer_id}`
**Specification file**: `paths/customers/Customer.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:331-335`

**What happens**: Same behavior as POST. If `photo_url` is included in the request body, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: Same as POST. The field is visible in the schema but cannot be set.

**Recommendation**: Same as POST. Mark `photo_url` as read-only in the schema and reference the upload-photo endpoint.

---

### 11. DELETE /customers - Not supported

**Endpoint**: `DELETE /customers/{customer_id}`
**Specification file**: `paths/customers/Customer.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:113-116`

**What happens**: The DELETE method is explicitly not supported. The controller method `getContentDeleteCustomer` throws `HttpMethodNotSupportedException`, which returns HTTP 405 (Method Not Allowed).

**Why it matters**: An integrator may expect a DELETE method to exist for resource management. The specification should make clear that customer deletion is not available through the REST API.

**Recommendation**: Add a note in the GET or PUT description, or in a separate section, stating that the DELETE method is not supported for customers. If there is an alternative workflow for deactivating customers (e.g., setting a status), reference it.

---

### 12. POST /customers/actions/set-status-record - valid_from must not be in the future

**Endpoint**: `POST /customers/actions/set-status-record`
**Specification file**: `paths/customers/CustomerSetStatusRecord.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:1260-1271`

**What happens**: The `valid_from` value must be equal to or earlier than the current timestamp. If a future date is provided, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "The status in CareCloud must have a valid start date that is now or in the past."

The specification already documents that `valid_from` defaults to the current timestamp when not provided. However, the future-date restriction is not documented.

**Why it matters**: An integrator scheduling a future status activation would receive an unexpected error. This constraint is specific to how CareCloud handles status records and cannot be inferred from the field description.

**Recommendation**: Add to the `valid_from` field description that it must be the current date/time or a past date. Future dates are rejected.

---

### 13. POST /customers/actions/set-status-record - valid_from must be less than or equal to valid_to

**Endpoint**: `POST /customers/actions/set-status-record`
**Specification file**: `paths/customers/CustomerSetStatusRecord.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:1285-1296`

**What happens**: If both `valid_from` and `valid_to` are provided, `valid_from` must be less than or equal to `valid_to`. If `valid_from` is greater, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "valid_from is greater than valid_to."

**Why it matters**: While logically obvious, the specification does not state this constraint. Integrators generating dates programmatically should know about this validation.

**Recommendation**: Add a note that `valid_from` must be less than or equal to `valid_to` when both are provided.

---

### 14. POST /customers/actions/newsletters-sign-up - Behavior depends on existing account state

**Endpoint**: `POST /customers/actions/newsletters-sign-up`
**Specification file**: `paths/customers/CustomerNewslettersSignUp.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:1339-1653`

**What happens**: The endpoint's behavior depends on whether the contact already has an account:

1. **No existing account**: A new non-club account is created with the provided contact, customer source, agreements, language, and partner records. The membership level is determined by the customer source configuration, falling back to the project's non-club membership level.
2. **Existing non-deleted account**: No new account is created. Instead, the system updates the existing account: sets the provided consents, adds the provided partners (without removing existing ones), and if the account is non-club and the customer source has a linked membership level, updates the membership level. The customer source is linked to the account if not already linked.
3. **Existing deleted account**: Returns HTTP 400 with reason `deleted` and the message "Update of deleted customer is not possible."

**Why it matters**: The specification says "Sign up a contact for the newsletter. The contact does not need to be an existing customer." This does not explain what happens when the contact IS an existing customer. An integrator may not expect that calling this endpoint for an existing customer modifies their consents, partners, and potentially their membership level.

**Recommendation**: Document the three-way behavior based on account state. Explain what is created or modified in each case. Note that for existing accounts, consents and partners are added (not replaced), and the membership level may be upgraded if the customer source has a linked membership level.

---

### 15. POST /customers/actions/newsletters-sign-up - Default language assignment

**Endpoint**: `POST /customers/actions/newsletters-sign-up`
**Specification file**: `paths/customers/CustomerNewslettersSignUp.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:1549-1550`

**What happens**: When `language_id` is not provided, the system assigns the project's default communication language to the new account. For existing accounts, the language is updated only if `language_id` is explicitly provided in the request (line 1637).

**Why it matters**: The specification does not mention a default language assignment. An integrator who omits `language_id` expecting no language to be set will find the project's default language on the account.

**Recommendation**: Add to the `language_id` field description that when omitted, the project's default language is used for new accounts. For existing accounts, omitting `language_id` leaves the current language unchanged.

---

### 16. POST /customers/actions/verify-credentials - Deleted accounts always fail

**Endpoint**: `POST /customers/actions/verify-credentials`
**Specification file**: `paths/customers/CustomerVerifyCredentials.yaml`
**Controller**: `CustomersResourceControllerV1v0.class.php:848-850`

**What happens**: After successful password verification, the system checks whether the account is deleted. If the account is deleted, the endpoint returns the same `InvalidCustomerCredentialsException` as for incorrect credentials, without distinguishing between "wrong password" and "deleted account."

**Why it matters**: An integrator using this endpoint for authentication cannot distinguish between invalid credentials and a deleted account. Both cases return the same error response. If the integrator needs to show a specific message for deleted accounts (e.g., "Your account has been deactivated"), they cannot do so based on this endpoint's response alone.

**Recommendation**: Document that deleted accounts always fail verification regardless of whether the credentials are correct. Note that the error response does not distinguish between invalid credentials and a deleted account.

---

## Cards

### 17. PUT /cards/{card_id} - Card blocking is rate-limited per card type in Customer API

**Endpoint**: `PUT /cards/{card_id}`
**Specification file**: `paths/cards/Card.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:142-150`

**What happens**: When called from Customer API and the card state is being set to 0 (blocked), the system checks whether the customer has already blocked a card of the same type recently. If so, the request is rejected with HTTP 400 and the message "The card could not be blocked, because another card of the same type was blocked recently."

**Why it matters**: This is a rate-limiting mechanism to prevent abuse of card blocking. It is not documented and an integrator would not know that repeated blocking requests for the same card type can be rejected.

**Recommendation**: Document that in Customer API, blocking a card (setting state to 0) is subject to a rate limit per card type. If another card of the same type was recently blocked, the request is rejected.

---

### 18. POST /cards/actions/assign-free-card - Deleted customers are rejected as not found

**Endpoint**: `POST /cards/actions/assign-free-card`
**Specification file**: `paths/cards/CardAssign.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:345-352`

**What happens**: If the customer_id refers to a deleted customer, the endpoint returns HTTP 400 with reason `not_found`, the same response as for a non-existent customer. Deleted accounts are treated as non-existent for card assignment purposes.

**Why it matters**: The specification does not mention deleted customers. An integrator would not know that deleted customers cannot receive card assignments and that the error looks identical to a non-existent customer.

**Recommendation**: Document that deleted customers are treated as non-existent and cannot have cards assigned.

---

### 19. POST /cards/actions/assign-free-card - Auto-assignment when card_number is omitted

**Endpoint**: `POST /cards/actions/assign-free-card`
**Specification file**: `paths/cards/CardAssign.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:396-400`

**What happens**: When `card_number` is not provided, the system automatically selects and assigns an available unassigned card of the specified card type from the pool. When `card_number` is provided, it must refer to an existing unassigned card, and its type must match the `card_type_id` parameter (lines 385-393).

**Why it matters**: The specification marks `card_number` as optional but does not explain the behavioral difference between providing and omitting it. An integrator needs to know that omitting `card_number` triggers auto-assignment from the card pool, while providing it assigns a specific card.

**Recommendation**: Document the two assignment modes: (1) when `card_number` is provided, the specific card is assigned and its type must match `card_type_id`; (2) when omitted, an available card of the specified type is automatically selected from the pool.

---

### 20. POST /cards/actions/generate-digital-card-file - Card must be assigned to a customer

**Endpoint**: `POST /cards/actions/generate-digital-card-file`
**Specification file**: `paths/cards/CardGenerateDigital.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:429-436`

**What happens**: If the card is not assigned to any customer (unassigned card), the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "The card is not assigned to any customer. Virtual cards could be returned only if customer is assigned to the card."

**Why it matters**: The specification does not mention this requirement. An integrator generating digital card files for pre-imported, unassigned cards would receive an unexpected error.

**Recommendation**: Document that only cards assigned to a customer can generate digital card files. Unassigned cards are rejected.

---

### 21. POST /cards/actions/generate-passmachine-card - Default template fallback and failure

**Endpoint**: `POST /cards/actions/generate-passmachine-card`
**Specification file**: `paths/cards/CardGeneratePassMachine.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:504-513`

**What happens**: When `passmachine_template_id` is not provided, the system falls back to a default template from project configuration. If the default template is not configured or is empty, the endpoint returns HTTP 400 with the message "The PassMachine digital card could not be returned, because there is a missing or wrong template used." Additionally, even when a template ID is provided (or defaulted), the system validates it against the PassMachine service and rejects unknown template IDs with HTTP 400.

**Why it matters**: The specification says "If the parameter is not set, the default template is used" but does not warn that the default may not be configured, leading to a failure. An integrator relying on the default template behavior has no way to know whether the project has a default configured.

**Recommendation**: Document that when `passmachine_template_id` is omitted, the system uses the project's default template. If no default is configured, the request fails with HTTP 400. Also document that the template ID is validated against the PassMachine service.

---

### 22. POST /cards/actions/generate-passmachine-card - Deleted customers are rejected

**Endpoint**: `POST /cards/actions/generate-passmachine-card`
**Specification file**: `paths/cards/CardGeneratePassMachine.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:494-501`

**What happens**: If the customer_id refers to a deleted customer, the endpoint returns HTTP 400 with reason `not_found`. Deleted accounts are treated as non-existent, same as in the assign-free-card endpoint.

**Why it matters**: The specification does not mention this restriction. An integrator would not know that deleted customers cannot generate PassMachine cards.

**Recommendation**: Document that deleted customers cannot generate PassMachine digital cards.

---

### 23. POST /cards/actions/validate-free-card - Empty card number returns false instead of an error

**Endpoint**: `POST /cards/actions/validate-free-card`
**Specification file**: `paths/cards/CardValidateFree.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:561-567`

**What happens**: If the `card_number` is an empty string or whitespace, the endpoint returns `is_free_to_use: false` instead of a validation error. The schema marks `card_number` as required, but the controller silently handles the empty case.

**Why it matters**: An integrator expecting an HTTP 400 for an empty required field would instead receive a valid response with `false`, making it harder to distinguish between "card number is invalid input" and "card number exists but is not free."

**Recommendation**: Document that empty or whitespace-only card numbers always return `is_free_to_use: false` without a validation error.

---

### 24. POST /cards/actions/validate-isic-card - is_free_to_use is true when the card does not exist in CareCloud

**Endpoint**: `POST /cards/actions/validate-isic-card`
**Specification file**: `paths/cards/CardValidateIsic.yaml`
**Controller**: `CardsResourceControllerV1v0.class.php:586-598`

**What happens**: When `check_usage` is true and the ISIC card is valid, the `is_free_to_use` field has three possible outcomes: (1) the card exists in CareCloud as an unassigned card: `true`, (2) the card exists in CareCloud and is assigned: `false`, (3) the card does not exist in CareCloud at all: `true`. Case 3 is notable because a card that has never been imported into CareCloud is considered "free to use."

**Why it matters**: An integrator might expect a card not present in the system to return `false` (not usable) or an error, rather than `true` (free to use). The actual logic means "free to use" encompasses both unassigned cards and entirely unknown cards.

**Recommendation**: Document the three cases clearly. Explain that `is_free_to_use: true` means either the card is unassigned in CareCloud or the card number has not been imported into CareCloud yet. `is_free_to_use: false` means the card is already assigned to a customer.

---

## Purchases

### 25. PUT /purchases/{purchase_id} - Limited to customer_id and card_number fields only

**Endpoint**: `PUT /purchases/{purchase_id}`
**Specification file**: `paths/purchases/Purchase.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:890-911`

**What happens**: The PUT endpoint accepts the full `Purchase` schema in the request body, but the controller only reads and updates two fields: `customer_id` and `card_number`. All other fields in the `Purchase` schema (such as `store_id`, `total_price`, `payment_time`, etc.) are silently ignored.

**Why it matters**: The specification says "Update a specific purchase" and accepts the full Purchase schema, implying all purchase fields can be modified. An integrator sending a complete purchase object expecting fields like `total_price` or `payment_time` to be updated would find them unchanged without any error.

**Recommendation**: Document that PUT /purchases only updates the `customer_id` and `card_number` fields. All other fields in the request body are ignored. If a full purchase correction is needed, describe the alternative approach.

---

### 26. POST /purchases/actions/send-purchase - bill_id must be unique per store

**Endpoint**: `POST /purchases/actions/send-purchase`
**Specification file**: `paths/purchases/PurchaseSend.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:796-798`

**What happens**: If the `bill_id` in the request has already been used in a previous purchase (within the same store), the endpoint returns HTTP 400 with reason `already_exists`.

**Why it matters**: The `bill_id` field description does not mention the uniqueness constraint. An integrator retrying a failed request with the same `bill_id` would receive this error if the original request actually succeeded (e.g., due to a network timeout where the response was lost).

**Recommendation**: Document that `bill_id` must be unique per store. If a purchase with the same `bill_id` has already been recorded, the endpoint returns HTTP 400 with reason `already_exists`. Suggest that integrators can use this behavior for idempotency checks.

---

### 27. POST /purchases/actions/send-purchase - bill_item_id must be a non-empty string

**Endpoint**: `POST /purchases/actions/send-purchase`
**Specification file**: `paths/purchases/PurchaseSend.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:589-597`

**What happens**: Each bill item's `bill_item_id` is validated: an empty string (`""`) is rejected with HTTP 400 and reason `not_allowed_value` with the message "bill_item_id cannot be empty string". A null `bill_item_id` is caught later as a required field.

**Why it matters**: The bill item schema does not document that `bill_item_id` is required or that an empty string is rejected differently from null.

**Recommendation**: Document that `bill_item_id` is required for each bill item and must be a non-empty string.

---

### 28. POST /purchases/actions/send-purchase - card_number and customer_id cross-validation

**Status**: Solved. Added a cross-validation note to the `card_number` field description in `paths/purchases/PurchaseSend.yaml`.

**Endpoint**: `POST /purchases/actions/send-purchase`
**Specification file**: `paths/purchases/PurchaseSend.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:871-881`

**What happens**: When both `customer_id` and `card_number` are provided, the controller verifies that the card belongs to the specified customer. If the card is assigned to a different customer, the endpoint returns HTTP 400 with reason `not_belong_to_logged_in_customer` on the `card_number` field.

**Why it matters**: The specification does not mention this cross-validation. An integrator providing both fields with a mismatch would receive an error that does not clearly explain the constraint.

**Recommendation**: Document across all purchase action endpoints that when both `customer_id` and `card_number` are provided, they must belong to the same customer. A mismatch returns HTTP 400.

---

### 29. POST /purchases/actions/send-purchase - item paid_amount must not exceed price

**Endpoint**: `POST /purchases/actions/send-purchase`
**Specification file**: `paths/purchases/PurchaseSend.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:800`

**What happens**: If any bill item has `paid_amount` greater than `price`, the endpoint returns HTTP 400 with reason `not_allowed_value` on `bill_item_id`.

**Why it matters**: The relationship between `price` and `paid_amount` is not documented. An integrator may assume `paid_amount` can exceed `price` (e.g., for tips or surcharges).

**Recommendation**: Document that `paid_amount` must not exceed `price` for each bill item.

---

### 30. POST /purchases/actions/send-purchase - Blocked card is rejected

**Endpoint**: `POST /purchases/actions/send-purchase`
**Specification file**: `paths/purchases/PurchaseSend.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:828-830`

**What happens**: If the provided `card_number` belongs to a blocked card, the endpoint returns HTTP 400 with reason `not_allowed_value` on the `card_number` field.

**Why it matters**: The specification does not mention card state validation. An integrator receiving this error without context about card blocking would not know how to resolve it.

**Recommendation**: Document across all purchase action endpoints that the card must be active. A blocked card returns HTTP 400.

---

### 31. POST /purchases/actions/send-purchase - Voucher validation rules

**Endpoint**: `POST /purchases/actions/send-purchase`
**Specification file**: `paths/purchases/PurchaseSend.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:780-795`

**What happens**: The payment recap's vouchers are validated against multiple conditions. Any of the following causes HTTP 400 with reason `not_allowed_value` on the `vouchers` field: voucher already used, voucher expired, voucher assigned to another account, voucher cannot be used in the specified store, voucher cannot be applied by date/time/day-of-week, voucher requires a customer segment the customer is not in, insufficient purchase amount for the voucher, and exceeding the maximum number of vouchers.

**Why it matters**: While the specification documents that "Vouchers selected at bill closure are marked as used", it does not list the specific validation rules that can cause rejection.

**Recommendation**: Document the voucher validation rules and the conditions under which a voucher is rejected: voucher already used, expired, assigned to a different customer, not valid in the specified store, or not valid at the current date/time.

---

### 32. POST /purchases/actions/assign-customer - Requires either customer_id or card_number

**Endpoint**: `POST /purchases/actions/assign-customer`
**Specification file**: `paths/purchases/PurchaseAssignCustomer.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:232-249`

**What happens**: At least one of `customer_id` or `card_number` must be provided. If both are null or both are missing, the endpoint returns HTTP 400 with reason `required` and the message "At least one of params customer_id|card_number is necessary." An empty `card_number` (empty string) is treated the same as null.

**Why it matters**: The specification describes both fields as individually optional with notes that each "is mandatory only if [the other] is not set", but does not explicitly state that at least one must be provided as a formal validation rule.

**Recommendation**: Add a clear validation note: at least one of `customer_id` or `card_number` must be provided as a non-empty value.

---

### 33. POST /purchases/actions/accept-payment - Point and credit balance validation

**Endpoint**: `POST /purchases/actions/accept-payment`
**Specification file**: `paths/purchases/PurchaseAcceptPayment.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:764-766`

**What happens**: If `max_points` exceeds the customer's available point balance, the endpoint returns HTTP 400 with reason `not_allowed_value`. The same applies to `max_credit` if the customer's account cannot pay with credits (line 817-818).

**Why it matters**: The specification describes `max_points` and `max_credit` as simple numeric inputs without documenting the validation against the customer's actual balance or account permissions.

**Recommendation**: Document that `max_points` cannot exceed the customer's available point balance and `max_credit` cannot exceed the available credit balance. Note that paying with points or credits may be disabled for certain accounts based on project configuration.

---

### 34. POST /purchases/actions/accept-payment - payment_type enforces benefit eligibility

**Endpoint**: `POST /purchases/actions/accept-payment`
**Specification file**: `paths/purchases/PurchaseAcceptPayment.yaml`
**Controller**: `PurchasesResourceControllerV1v0.class.php:413`

**What happens**: The `payment_type` value controls which benefits (points, discounts, credits) can be applied. Type `S` collects points but blocks overall discounts, `A` allows both, `C` enables credit payment but blocks discounts, `D` enables discounts but blocks point collection. These rules are enforced at the POS level, not just as presentation hints.

**Why it matters**: The specification description reads as documentation of display options, but these are actually enforced business rules. An integrator who sends `payment_type: S` with discount codes would have the discounts silently ignored or rejected.

**Recommendation**: Clarify that `payment_type` enforces benefit eligibility at the POS level. Document each value's enforcement rules: which benefits are allowed and which are blocked.

---

## Points

### 35. POST /points/actions/assign-points - partner_id conditionally required

**Endpoint**: `POST /points/actions/assign-points`
**Specification file**: `paths/points/PointsAssign.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:3904-3922`

**What happens**: The specification lists `partner_id` as required. However, if the authenticated API user has access to exactly one partner, `partner_id` can be omitted and that partner is used automatically. If the user has access to multiple partners and `partner_id` is omitted, the endpoint returns HTTP 400 with reason `required` and the message "It is required to specify partner, more than one are available."

The same validation method (`checkPartnerIdForPoints`) applies to both the assign and redemption endpoints.

**Why it matters**: An integrator who discovers the auto-resolution may rely on it, then encounter errors if the API user is later granted access to additional partners.

**Recommendation**: Document that `partner_id` can be omitted when the API user has access to exactly one partner. When the API user has access to multiple partners, `partner_id` is required. This applies to both the assign and redemption endpoints.

---

### 36. POST /points/actions/synchronize-points - Customer's membership level must allow point collection

**Endpoint**: `POST /points/actions/synchronize-points`
**Specification file**: `paths/points/PointsSynchronize.yaml`
**Controller**: `PointsResourceControllerV1v0.class.php:414-423`

**What happens**: Before synchronizing, the controller checks whether the customer's current membership level allows point collection. If the membership level does not permit collecting points, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "The customer is not able to collect points. Please change the customer status or allow the current status to collect points."

**Why it matters**: The specification does not mention this prerequisite. An integrator may attempt to synchronize points for a customer whose membership level disables point collection and receive an unexpected error.

**Recommendation**: Document that the customer's current membership level (status) must allow point collection. If the membership level does not permit it, the operation is rejected.

---

### 37. POST /points/actions/synchronize-points - Requires a synchronization point type in project configuration

**Endpoint**: `POST /points/actions/synchronize-points`
**Specification file**: `paths/points/PointsSynchronize.yaml`
**Controller**: `PointsResourceControllerV1v0.class.php:462-471`

**What happens**: The operation requires a dedicated "synchronization" point type to be configured in the CareCloud project. If this point type does not exist, the endpoint returns HTTP 400 with reason `not_found` and the message "The point type required to perform synchronization is not set, please contact CareCloud project administrator."

**Why it matters**: This is a project configuration prerequisite that the specification does not mention. An integrator calling the endpoint for the first time on a project where the synchronization point type has not been set up will receive a confusing error.

**Recommendation**: Document that the synchronize-points operation requires a dedicated synchronization point type to be configured in the CareCloud project.

---

### 38. POST /points/actions/synchronize-points - No operation when balance matches target

**Endpoint**: `POST /points/actions/synchronize-points`
**Specification file**: `paths/points/PointsSynchronize.yaml`
**Controller**: `PointsResourceControllerV1v0.class.php:475-491`

**What happens**: The synchronization compares the customer's current available points to the requested `amount`. If the current balance is higher, points are removed (the difference). If lower, points are assigned (the difference). If the balance already equals the target amount, no point operation is created and the endpoint returns 204 without creating any record.

**Why it matters**: The specification says "Set the value that will represent how many points the customer carries currently" but does not explain the comparison mechanism. An integrator may expect a new point record to appear after every synchronization call, but no record is created when the balance already matches.

**Recommendation**: Document that synchronization works by comparing the current available points to the target amount and only creating a point assignment or reduction record for the difference. When the balance already matches the target, no operation is performed.

---

### 39. POST /points/actions/transfer-points - Zero amount rejected

**Endpoint**: `POST /points/actions/transfer-points`
**Specification file**: `paths/points/PointsTransfer.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4019-4026`

**What happens**: If `amount` is set to 0, the endpoint returns HTTP 400 with reason `empty`. The specification does not document a minimum value for the amount field.

**Why it matters**: An integrator may programmatically calculate a transfer amount that could be zero. The error response uses the reason `empty` rather than a more descriptive reason, which could be confusing.

**Recommendation**: Document that `amount` must be greater than zero.

---

### 40. POST /points/actions/transfer-points - Insufficient points returns 400

**Endpoint**: `POST /points/actions/transfer-points`
**Specification file**: `paths/points/PointsTransfer.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4119-4126`

**What happens**: If the original customer does not have enough available points, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "customer doesnt have enough points."

**Why it matters**: The specification does not mention that the transfer is validated against available points.

**Recommendation**: Document that the transfer validates whether the original customer has sufficient available points of the specified type. If not, the operation is rejected.

---

### 41. POST /point-reservations/actions/reserve-points - external_id must be unique

**Endpoint**: `POST /point-reservations/actions/reserve-points`
**Specification file**: `paths/points/PointReservationCreate.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:3147-3159`

**What happens**: Before creating a point reservation, the system checks whether a reservation with the same `external_id` already exists. If it does, the endpoint returns HTTP 400 with reason `already_exists`.

**Why it matters**: The specification describes `external_id` as "The external unique ID of the point reservation" but does not explicitly state that uniqueness is enforced at the server level. An integrator retrying a failed reservation request with the same `external_id` will receive an error if the first request actually succeeded.

**Recommendation**: Document that `external_id` must be unique across all point reservations. A duplicate `external_id` returns HTTP 400 with reason `already_exists`. This can serve as an idempotency key.

---

### 42. POST /point-reservations/actions/reserve-points - Validates sufficient available points

**Endpoint**: `POST /point-reservations/actions/reserve-points`
**Specification file**: `paths/points/PointReservationCreate.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:3174-3178`

**What happens**: The system checks whether the customer has enough available points (scoped to the partners the API user has access to). If the customer's available points are less than the requested reservation amount, the endpoint returns HTTP 400 with the message "Insufficient amount of available points."

**Why it matters**: The specification does not mention that available points are validated. Additionally, the validation is partner-scoped: the available points checked are those associated with the API user's accessible partners, not the customer's total points.

**Recommendation**: Document that the customer must have sufficient available points (within the API user's partner scope) to cover the reservation amount.

---

### 43. POST /point-reservations/actions/free-points - Sets reservation state to "used"

**Endpoint**: `POST /point-reservations/actions/free-points`
**Specification file**: `paths/points/PointReservationRelease.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:3120-3140`

**What happens**: The "free points" (release) operation sets the reservation state to `STATE_USED`. Despite the endpoint being described as "Release reserved points" and "Free points from reservation," the internal state transition marks the reservation as "used" rather than "released" or "cancelled."

**Why it matters**: An integrator reading back point reservation records will see the state as "used" for reservations that were released, which may cause confusion. The naming suggests the points were consumed for a purchase, when in fact they were returned to the available balance.

**Recommendation**: Document the state values a point reservation can have and clarify what the "free points" operation does to the reservation state. If "used" is the intended terminal state for released reservations, explain that it means "the reservation lifecycle is complete" rather than "the points were spent."

---

### 44. GET /point-history - Non-existent customer returns 400, not empty results

**Endpoint**: `GET /point-history`
**Specification file**: `paths/points/PointHistory.yaml`
**Controller**: `PointsResourceControllerV1v0.class.php:298-306`

**What happens**: The `customer_id` query parameter is required. If the provided `customer_id` does not correspond to an existing customer, the endpoint returns HTTP 400 with reason `not_found` instead of returning an empty result set.

**Why it matters**: Standard REST convention for list endpoints with filters is to return an empty collection when no results match. Returning HTTP 400 for a non-existent filter value is unexpected.

**Recommendation**: Document that `customer_id` is validated against existing customer records and returns HTTP 400 if the customer does not exist, rather than an empty list.

---

## Credits

### 45. POST /credits/actions/deposit - Membership level must allow credits

**Endpoint**: `POST /credits/actions/deposit`
**Specification file**: `paths/credits/CreditDeposit.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:7624-7632`

**What happens**: Before depositing credits, the system checks whether the customer's membership level allows credit usage. If the membership level does not permit credits, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "The customer cannot use credit."

**Why it matters**: The specification does not mention that credit operations are restricted by membership level. An integrator attempting to deposit credits to a customer whose membership level does not support credits would receive an unexpected error.

**Recommendation**: Document that the customer's membership level must allow credit usage. If it does not, the deposit is rejected with HTTP 400.

---

### 46. POST /credits/actions/deposit - Partner ACL validation

**Endpoint**: `POST /credits/actions/deposit`
**Specification file**: `paths/credits/CreditDeposit.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:7595-7603`

**What happens**: The `partner_id` is validated against the authenticated API user's access control list. If the API user does not have access to the specified partner, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification describes `partner_id` as a required field but does not mention that it must be a partner the API user has access to.

**Recommendation**: Add a note to the `partner_id` field description stating that the partner must be accessible to the authenticated API user.

---

### 47. POST /credits/actions/deposit - Deposit triggers a credit addition event

**Endpoint**: `POST /credits/actions/deposit`
**Specification file**: `paths/credits/CreditDeposit.yaml`
**Controller**: `CreditsServices.class.php:144-155`

**What happens**: After a credit is deposited, the system registers a credit addition event via `registerCreditAdditionEvent`. This event can trigger marketing automation workflows configured in CareCloud. If the event registration fails, the credit deposit still succeeds (the exception is caught and logged, not propagated).

**Why it matters**: An integrator using credit deposits as part of a business workflow should know that deposits can trigger automated marketing actions. The event failure being non-blocking is also relevant.

**Recommendation**: Document that depositing credits triggers an internal event that may activate marketing automation workflows. Note that event registration failure does not affect the deposit itself.

---

### 48. POST /credits/actions/deposit - Available credits are recalculated

**Endpoint**: `POST /credits/actions/deposit`
**Specification file**: `paths/credits/CreditDeposit.yaml`
**Controller**: `CreditsServices.class.php:142`

**What happens**: After a deposit, the system calls `clearAvailableCredits`, which recalculates the `available_credits` balance across all credit records for the customer. This process locks credit rows, iterates through all positive and negative records in creation order, and recomputes the available balance for each record.

**Why it matters**: An integrator reading back credit records immediately after a deposit may observe that `available_credits` values on other credit records have changed, not just the newly deposited one.

**Recommendation**: Document that depositing or reducing credits triggers a recalculation of available credit balances across all of the customer's credit records.

---

### 49. POST /credits/actions/reduce - Insufficient balance returns 400

**Endpoint**: `POST /credits/actions/reduce`
**Specification file**: `paths/credits/CreditReduce.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:7565-7573`, `CreditsServices.class.php:635-637`

**What happens**: Before reducing credits, the system checks the customer's disposable debit balance. If the requested reduction amount exceeds the available balance, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "The credit couldn't be reduced because it was constrained by the customer's limit." No partial reduction is performed.

**Why it matters**: The specification does not document that the reduction amount is validated against the available balance, or what happens when the balance is insufficient.

**Recommendation**: Document that the reduction amount must not exceed the customer's available credit balance. If it does, the entire reduction is rejected (no partial reductions are performed).

---

### 50. POST /credits/actions/reduce - Membership level must allow credits

**Endpoint**: `POST /credits/actions/reduce`
**Specification file**: `paths/credits/CreditReduce.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:7624-7632`

**What happens**: Same membership level check as deposit. The customer's membership level must allow credit usage, otherwise the reduction is rejected with HTTP 400.

**Why it matters**: Same as deposit. The specification does not mention this restriction.

**Recommendation**: Same as deposit. Document the membership level requirement.

---

### 51. POST /credits/actions/reduce - Different default credit type than deposit

**Endpoint**: `POST /credits/actions/reduce`
**Specification file**: `paths/credits/CreditReduce.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:7522`

**What happens**: When `credit_type_id` is not provided, the reduction uses a different default credit type than the deposit. The deposit defaults to the "credit addition" type, while the reduction defaults to the "debit" type. These are distinct credit type records in the system.

**Why it matters**: The specification says "If the parameter is not set, a default credit type is set" for both deposit and reduce, implying they use the same default. In reality, each operation has its own default credit type. An integrator relying on the default for both operations would create credit records with different types.

**Recommendation**: Clarify in both deposit and reduce descriptions that each operation has its own project-default credit type. Specify that the deposit default and the reduction default are different credit types.

---

### 52. POST /credits/actions/transfer - Amount must be positive

**Endpoint**: `POST /credits/actions/transfer`
**Specification file**: `paths/credits/CreditTransfer.yaml`
**Controller**: `CreditsServices.class.php:859-861`

**What happens**: The transfer amount must be a positive number (greater than zero). If zero or negative, the endpoint returns HTTP 400 with reason `invalid_value_format` and the message "Amount of transferred credits should be a positive number."

**Why it matters**: The specification does not state the minimum value for the amount field.

**Recommendation**: Document that the transfer amount must be a positive number greater than zero.

---

### 53. POST /credits/actions/transfer - Insufficient balance on source customer

**Endpoint**: `POST /credits/actions/transfer`
**Specification file**: `paths/credits/CreditTransfer.yaml`
**Controller**: `CreditsServices.class.php:863-867`

**What happens**: The system checks the source customer's available credit balance for the specified currency. If the available balance is less than the transfer amount, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "Not enough credits for transferring."

**Why it matters**: The specification does not document the balance check or the error response when the source customer has insufficient credits.

**Recommendation**: Document that the source customer must have sufficient available credits in the specified currency. If the balance is insufficient, the transfer is rejected entirely.

---

### 54. POST /credits/actions/transfer - Both customers' membership levels must allow credits

**Endpoint**: `POST /credits/actions/transfer`
**Specification file**: `paths/credits/CreditTransfer.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:7735-7743`, `CrmInterfaceForWebservice.class.php:7765-7773`

**What happens**: Both the source customer and the destination customer must have membership levels that allow credit usage. If either customer's membership level does not support credits, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "The customer cannot use credit."

**Why it matters**: The specification does not mention this restriction for either customer.

**Recommendation**: Document that both customers must have membership levels that allow credit usage. If either does not, the transfer is rejected.

---

### 55. POST /credits/actions/transfer - Credits are deducted from earliest-expiring records first

**Endpoint**: `POST /credits/actions/transfer`
**Specification file**: `paths/credits/CreditTransfer.yaml`
**Controller**: `CreditsServices.class.php:870-873`

**What happens**: When transferring credits, the system deducts from the source customer's credit records ordered by validity date ascending. Records with the earliest expiry date are consumed first. If a single credit record does not cover the full transfer amount, multiple records are consumed. The resulting deposit on the destination customer preserves the partner association from each source record. The transferred credits receive no expiry date on the destination account.

**Why it matters**: The specification describes the transfer as a simple balance move. In reality, the transfer interacts with individual credit records and their expiry dates. The destination customer may receive multiple credit deposits if the source credits span multiple partners.

**Recommendation**: Document that credits are deducted from the source customer's earliest-expiring records first. Note that the transfer may result in multiple credit deposit records on the destination customer if the source credits belong to different partners. The transferred credits receive no expiry date on the destination account.

---

### 56. GET /credit-history - Partner ACL validation

**Endpoint**: `GET /credit-history`
**Specification file**: `paths/credits/CreditHistory.yaml`
**Controller**: `CreditHistoryResourceControllerV1v0.class.php:56-70`

**What happens**: When the `partner_id` query parameter is provided, the system validates it against the authenticated API user's access control list. If the API user does not have access to the specified partner, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "This partner is not allowed to use."

**Why it matters**: The specification lists `partner_id` as an optional filter but does not mention that it is ACL-restricted. An integrator filtering credit history by a partner they do not have access to would receive an unexpected error instead of an empty result set.

**Recommendation**: Add a note to the `partner_id` parameter description stating that only partners accessible to the authenticated API user can be used as a filter.

---

### 57. GET /credits - Invalid credit_type_id values are silently filtered

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /credits`
**Specification file**: `paths/credits/Credits.yaml`
**Controller**: `CreditsResourceControllerV1v0.class.php:96-117`

**What happens**: The `credit_type_id` query parameter accepts multiple values. Invalid IDs (ones that cannot be decoded or do not correspond to an existing credit type) are silently skipped. If all provided IDs are invalid, the endpoint returns an empty result set with no error.

**Why it matters**: An integrator passing an incorrect credit type ID would receive an empty result set instead of an error, making it difficult to diagnose the problem. The silent filtering is inconsistent with the action endpoints, where invalid IDs always produce HTTP 400.

**Recommendation**: Document that the `credit_type_id` filter silently ignores invalid or non-existent credit type IDs. If all provided IDs are invalid, the response is an empty list, not an error.

---

## Rewards

### 58. POST /rewards/{reward_id}/actions/create-voucher - Points are deducted from customer

**Endpoint**: `POST /rewards/{reward_id}/actions/create-voucher`
**Specification file**: `paths/rewards/RewardCreateVoucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4245-4256`, `VouchersServices.class.php:146`

**What happens**: If the reward has a points cost greater than zero, creating the voucher deducts the reward's points cost from the customer's point balance. If the customer does not have enough points, the request returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not mention that creating a voucher deducts points. An integrator calling this endpoint to issue a reward may not expect the customer's point balance to change as a side effect. This is critical for point reconciliation.

**Recommendation**: Document that when the reward has a points cost, the corresponding points are deducted from the customer's balance upon voucher creation. Note that the request fails if the customer does not have sufficient points.

---

### 59. POST /rewards/{reward_id}/actions/create-voucher - Voucher assignment event is registered

**Endpoint**: `POST /rewards/{reward_id}/actions/create-voucher`
**Specification file**: `paths/rewards/RewardCreateVoucher.yaml`
**Controller**: `VouchersServices.class.php:132-134`

**What happens**: After the voucher is created, the system automatically registers an internal "assigning voucher" event if the voucher has an assigned customer. This event can trigger marketing automation workflows.

**Why it matters**: Integrators tracking events or building automation around event types should know that voucher creation produces an event record.

**Recommendation**: Document that voucher creation registers an internal event of type "voucher assignment." This event can trigger marketing automation rules configured in CareCloud.

---

### 60. POST /rewards/{reward_id}/actions/create-voucher - Segment restriction on customer

**Endpoint**: `POST /rewards/{reward_id}/actions/create-voucher`
**Specification file**: `paths/rewards/RewardCreateVoucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4192-4200`

**What happens**: If the reward is configured with a segment restriction, the system checks whether the customer belongs to that segment. If the customer is not in the reward's segment, the request returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not mention segment-based eligibility. An integrator listing available rewards for a customer and then attempting to create a voucher may receive an unexpected error if the reward has a segment restriction.

**Recommendation**: Document that rewards may have segment restrictions. A voucher can only be created for a customer who belongs to the segment assigned to the reward.

---

### 61. POST /rewards/{reward_id}/actions/create-voucher - Repetitions limit per customer

**Endpoint**: `POST /rewards/{reward_id}/actions/create-voucher`
**Specification file**: `paths/rewards/RewardCreateVoucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4203-4211`

**What happens**: The system checks whether the customer has exceeded the maximum number of times the reward can be redeemed. If exceeded, the request returns HTTP 400 with reason `not_allowed_value` and the message "Customer exceeded Maximum Repetitions Limit."

**Why it matters**: The specification does not mention a repetitions limit. An integrator attempting to issue the same reward to a customer multiple times may receive an unexpected error after the limit is reached.

**Recommendation**: Document that rewards may have a maximum repetitions limit per customer. Once the limit is reached, no further vouchers can be created from that reward for that customer.

---

### 62. POST /rewards/{reward_id}/actions/create-voucher - Inactive reward is rejected

**Endpoint**: `POST /rewards/{reward_id}/actions/create-voucher`
**Specification file**: `paths/rewards/RewardCreateVoucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4213-4221`

**What happens**: If the reward's state is not active, the request returns HTTP 400 with reason `not_allowed_value` and the message "Invalid reward state."

**Why it matters**: The specification does not mention that the reward must be active. An integrator querying rewards with `is_valid=false` and then attempting to create a voucher from an inactive reward would receive an error.

**Recommendation**: Document that the reward must be in active state to create a voucher from it.

---

### 63. POST /rewards/{reward_id}/actions/create-voucher - PVT and campaign rewards are rejected

**Endpoint**: `POST /rewards/{reward_id}/actions/create-voucher`
**Specification file**: `paths/rewards/RewardCreateVoucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4235-4243`

**What happens**: If the reward is a PVT (Party Time / cash desk reward) or a campaign reward, the request returns HTTP 400 with reason `not_allowed_value` and the message "This reward could be used only in the purchase checkout process. You can't create a voucher with the reward this way."

**Why it matters**: The specification mentions "Only Coupons & Catalogue reward or Simple reward can be used here" but does not explain the specific error or that PVT/campaign rewards are checkout-only.

**Recommendation**: Expand the existing warning to explain that PVT (cash desk / party time) rewards and campaign rewards can only be applied during the purchase checkout process and cannot be issued as standalone vouchers through this endpoint.

---

### 64. POST /rewards/{reward_id}/actions/create-custom-voucher - Minimum voucher value enforcement

**Endpoint**: `POST /rewards/{reward_id}/actions/create-custom-voucher`
**Specification file**: `paths/rewards/RewardCreateCustomVoucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4387-4404`

**What happens**: The reward may have a configured minimum voucher value. If the `value` parameter in the request is less than this minimum, the request returns HTTP 400 with reason `not_allowed_value` and the message "The minimum value of the voucher is [value]."

**Why it matters**: The specification does not mention a minimum value constraint. An integrator sending a small value would receive an error with no prior indication that a minimum exists.

**Recommendation**: Document that the `value` parameter must meet the reward's configured minimum voucher value. Note that this minimum is reward-specific and can be checked via reward properties.

---

### 65. GET /rewards - Reward code is trimmed before filtering

**Status**: Not important for integrators. Standard input sanitization (whitespace trimming) applied before filtering.

**Endpoint**: `GET /rewards`
**Specification file**: `paths/rewards/Rewards.yaml`
**Controller**: `RewardsResourceControllerV1v0.class.php:104-110`

**What happens**: When filtering by the `code` query parameter, the value is passed through `trimVoucherTypeUidCode()` before being used as a filter. This trims the code according to internal formatting rules.

**Why it matters**: An integrator passing a code with leading/trailing whitespace or other characters that the trim removes may not realize their input is being modified.

**Recommendation**: Document that the `code` parameter value is normalized (trimmed) before filtering.

---

### 66. GET /rewards - without_stores default is project-configurable

**Endpoint**: `GET /rewards`
**Specification file**: `paths/rewards/Rewards.yaml`
**Controller**: `RewardsResourceControllerV1v0.class.php:325-337`

**What happens**: When the `without_stores` query parameter is not provided, the default behavior is determined by a project configuration value. The specification says "If true or not set, the data will not contain information about business units (stores)." This contradicts the implementation, where the default depends on project configuration and may be `false`.

**Why it matters**: The specification claims that omitting `without_stores` excludes stores from the response, but the actual behavior depends on project configuration.

**Recommendation**: Correct the `without_stores` parameter description. Document that the default behavior when the parameter is omitted depends on project configuration.

---

### 181. GET /rewards - Non-existent filter IDs return 400 instead of empty results

**Endpoint**: `GET /rewards`
**Specification file**: `paths/rewards/Rewards.yaml`
**Controller**: `RewardsResourceControllerV1v0.class.php:238-286`

**What happens**: The endpoint validates four query parameters against the database before running the list query: `customer_id` (calls `getAccountByIdcont`), `customer_type_id` (calls `getRewardsUseTypeById`), `tag_ids` (calls `getEntityById` for each tag), and `store_id` (calls `getStoreById`). If any referenced resource does not exist, the endpoint returns HTTP 400 with reason `not_found`.

**Why it matters**: The general filtering rule across the API is that a filter referencing a non-existent resource returns an empty result set, not an error. This endpoint breaks that rule for four parameters. The behavior is inconsistent with, for example, GET /products, where invalid `tag_id[]` values are silently skipped.

**Recommendation**: Document the validation behavior for these four parameters, or align the endpoint with the general filtering rule.

---

### 67. POST /rewards/actions/create-simple-reward - Accept-Language determines required name language

**Endpoint**: `POST /rewards/actions/create-simple-reward`
**Specification file**: `paths/rewards/RewardCreateSimpleReward.yaml`
**Controller**: `RewardsResourceControllerV1v0.class.php:806-822`

**What happens**: The `names` array must include a translation for the language specified in the `Accept-Language` header. If the active language is not present in the `names` array, the request returns HTTP 400 with reason `required` and the message "Required language [iso_code] (from Accept-Language) is missing. Please insert translation."

**Why it matters**: The specification does not mention that the language from Accept-Language must be present in the names array.

**Recommendation**: Document that the `names` array must include a translation for the language specified in the Accept-Language header.

---

### 68. POST /rewards/actions/create-simple-reward - valid_date_from must be less than or equal to valid_date_to

**Endpoint**: `POST /rewards/actions/create-simple-reward`
**Specification file**: `paths/rewards/RewardCreateSimpleReward.yaml`
**Controller**: `RewardsResourceControllerV1v0.class.php:824-835`

**What happens**: If both `valid_date_from` and `valid_date_to` are provided and `valid_date_from` is greater than `valid_date_to`, the request returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not document this validation constraint.

**Recommendation**: Document that `valid_date_from` must be less than or equal to `valid_date_to` when both are provided.

---

### 69. POST /rewards/actions/create-simple-reward - Reward type restrictions

**Endpoint**: `POST /rewards/actions/create-simple-reward`
**Specification file**: `paths/rewards/RewardCreateSimpleReward.yaml`
**Controller**: `RewardsResourceControllerV1v0.class.php:922-943`

**What happens**: Not all reward types can be used when creating a simple reward. If the reward type is not supported, the request returns HTTP 400 with reason `not_allowed_value` listing the currently supported types: "Product with fixed discount / Product with a discount in percentages / Product for discounted price."

**Why it matters**: The specification does not document which reward types are valid for simple reward creation.

**Recommendation**: Document the supported reward types for simple reward creation and reference the `GET /reward-types` endpoint for the full list.

---

## Vouchers

### 70. GET /vouchers - Voucher code is trimmed at the hyphen

**Status**: Not important for integrators. Everything after the hyphen is internal processing data. The database stores only the code prefix, so the trimming aligns the filter with the stored value.

**Endpoint**: `GET /vouchers`
**Specification file**: `paths/vouchers/Vouchers.yaml`
**Controller**: `VouchersResourceControllerV1v0.class.php:91-97`

**What happens**: When filtering vouchers by the `code` query parameter, the code value is trimmed at the first hyphen character. For example, a code filter of `ABC123-XYZ` is converted to `ABC123` before the query runs.

**Why it matters**: An integrator passing a full voucher code (which may contain hyphens as part of its format) would unknowingly match a broader set of vouchers than intended.

**Recommendation**: Document that the `code` filter strips everything after the first hyphen before matching.

---

### 71. GET /vouchers - Used vouchers excluded when is_applied is false

**Endpoint**: `GET /vouchers`
**Specification file**: `paths/vouchers/Vouchers.yaml`
**Controller**: `VouchersResourceControllerV1v0.class.php:194-196`

**What happens**: When `is_applied=false`, the list endpoint additionally checks whether each customer-assigned voucher has been used in a product reservation. Vouchers used in a reservation are excluded from the results, and the `total_items` count is adjusted accordingly. This is a post-query filter, so the returned count may be less than the requested `count`.

**Why it matters**: The `is_applied` filter description suggests it filters by whether the voucher was formally applied (has an apply date). The additional reservation-based exclusion is not documented and can cause pagination inconsistencies.

**Recommendation**: Document that `is_applied=false` excludes both formally applied vouchers and vouchers used in product reservations. Note the potential pagination effect.

---

### 72. DELETE /vouchers/{voucher_id} - Deleted voucher returns 400, not 404

**Endpoint**: `DELETE /vouchers/{voucher_id}`
**Specification file**: `paths/vouchers/Voucher.yaml`
**Controller**: `VouchersResourceControllerV1v0.class.php:369-377`

**What happens**: If the voucher is already deleted (state=0), the endpoint returns HTTP 400 with reason `deleted`. If the voucher is cancelled (state=-1), it returns HTTP 400 with a different message. Neither returns HTTP 404.

**Why it matters**: An integrator would expect that deleting an already-deleted resource returns HTTP 404 or is idempotent (returns 204). The distinction between deleted and cancelled states is not documented.

**Recommendation**: Document the voucher state restrictions: already-deleted vouchers return HTTP 400 with reason `deleted`, and cancelled vouchers cannot be deleted.

---

### 73. DELETE /vouchers/{voucher_id} - Points are refunded on deletion

**Endpoint**: `DELETE /vouchers/{voucher_id}`
**Specification file**: `paths/vouchers/Voucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:7917-7944`

**What happens**: When a voucher is deleted, the system refunds all loyalty points that were spent to purchase it. Each point transaction linked to the voucher is reversed by adding the spent quantity back to the customer's available points. A deleted voucher event is also registered.

**Why it matters**: The specification mentions "return of the loyalty points or credits" but does not explain the mechanism. An integrator should understand that deleting a voucher includes a financial refund.

**Recommendation**: Expand the description to explain that deletion reverses the point or credit transactions used to purchase the voucher, restoring the customer's balance.

---

### 74. DELETE /vouchers/{voucher_id} - "Used" voucher definition

**Endpoint**: `DELETE /vouchers/{voucher_id}`
**Specification file**: `paths/vouchers/Voucher.yaml`
**Controller**: `VouchersResourceControllerV1v0.class.php:387-398`

**What happens**: A voucher is considered "used" and cannot be deleted if any of the following is true: it has been partly used (has partial application records), it has a valid apply date, or it has an apply store assigned.

**Why it matters**: The specification says "you can delete only not used vouchers" but does not define what "used" means. Partial usage and store assignment without a formal apply date also block deletion.

**Recommendation**: Define what constitutes a "used" voucher: any voucher with partial application records, an apply date, or an apply store.

---

### 75. PUT /vouchers/{voucher_id} - customer_id is required

**Endpoint**: `PUT /vouchers/{voucher_id}`
**Specification file**: `paths/vouchers/Voucher.yaml`
**Controller**: `VouchersResourceControllerV1v0.class.php:295-302`

**What happens**: The `customer_id` field is required in the request body. If it is null or empty, the endpoint returns HTTP 400 with reason `empty`. This is not indicated in the specification schema.

**Why it matters**: An integrator using the Voucher schema definition would assume `customer_id` is optional in the PUT body. Attempting to update a voucher without `customer_id` fails unexpectedly.

**Recommendation**: Document that `customer_id` is required when updating a voucher.

---

### 76. PUT /vouchers/{voucher_id} - Code cannot contain hyphens or pipes

**Endpoint**: `PUT /vouchers/{voucher_id}`
**Specification file**: `paths/vouchers/Voucher.yaml`
**Controller**: `VouchersResourceControllerV1v0.class.php:293`, `CrmInterfaceForWebservice.class.php:9292-9325`

**What happens**: The voucher code is validated against a character restriction: codes containing `-` (hyphen) or `|` (pipe) characters are rejected with HTTP 400 and the error message "The parameter code contains not allowed characters."

**Why it matters**: There is no documentation of allowed or disallowed characters in voucher codes. An integrator generating codes with hyphens would receive an unexpected error.

**Recommendation**: Document the character restrictions for voucher codes: hyphens (`-`) and pipes (`|`) are not allowed.

---

### 77. PUT /vouchers/{voucher_id} - applied_date must be within validity range

**Endpoint**: `PUT /vouchers/{voucher_id}`
**Specification file**: `paths/vouchers/Voucher.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:6779-6815`

**What happens**: When updating a voucher with an `applied_date`, the date is validated against the voucher's validity range: it cannot be before `valid_from` or after `valid_to`.

**Why it matters**: The specification does not document any relationship between the applied date and the validity range.

**Recommendation**: Document that `applied_date` must fall within the `valid_from` and `valid_to` range when both are provided.

---

### 78. POST /vouchers/{voucher_id}/actions/apply - Voucher must be within its validity range

**Endpoint**: `POST /vouchers/{voucher_id}/actions/apply`
**Specification file**: `paths/vouchers/VoucherApply.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2689-2698`

**What happens**: The voucher must be currently valid at the time of the API call. If `valid_from` is in the future or `valid_to` is in the past, the endpoint returns HTTP 400 with reason `not_allowed_value` on a parameter named `non_valid_voucher`.

**Why it matters**: The specification does not mention validity range checks. The error uses a non-standard parameter name (`non_valid_voucher`) that does not match any request field.

**Recommendation**: Document that the voucher must be within its validity range at the time of application. Note the error parameter name for integrators building error handling.

---

### 79. POST /vouchers/{voucher_id}/actions/apply - Already-applied voucher is rejected

**Endpoint**: `POST /vouchers/{voucher_id}/actions/apply`
**Specification file**: `paths/vouchers/VoucherApply.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2700-2708`

**What happens**: If the voucher already has an apply date or an apply store, the endpoint returns HTTP 400 with reason `not_allowed_value` and parameter name `voucher_is_already_applied`. The apply operation is not idempotent.

**Why it matters**: The specification says "Sets a voucher as applied" but does not state that re-applying is rejected.

**Recommendation**: Document that a voucher can only be applied once. Re-applying a voucher returns HTTP 400. The operation is not idempotent.

---

### 80. POST /vouchers/batch - Party-time rewards are rejected

**Endpoint**: `POST /vouchers/batch`
**Specification file**: `paths/vouchers/VouchersBatch.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4476-4483`

**What happens**: Rewards of the "party time" type cannot be used to create vouchers via the batch endpoint. The error message is "This reward could be used only in the purchase checkout process."

**Why it matters**: The specification does not mention any reward type restrictions.

**Recommendation**: Document that certain reward types (party-time rewards) can only generate vouchers during the purchase checkout process and are not available for batch creation.

---

### 81. POST /vouchers/batch - Points deducted from customer balance

**Endpoint**: `POST /vouchers/batch`
**Specification file**: `paths/vouchers/VouchersBatch.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4541-4561`

**What happens**: If the reward has a point cost, the batch endpoint verifies the customer has sufficient available points and deducts them. If the customer does not have enough points, the voucher creation fails.

**Why it matters**: The specification describes the batch endpoint as a way to "add multiple vouchers" without mentioning that creating a voucher can deduct points from the customer's balance.

**Recommendation**: Document that voucher creation via batch deducts loyalty points from the customer's balance when the reward has a point cost.

---

### 82. POST /vouchers/batch - Reward repetitions limit check

**Endpoint**: `POST /vouchers/batch`
**Specification file**: `paths/vouchers/VouchersBatch.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:4563-4570`

**What happens**: The batch endpoint checks whether the customer has exceeded the maximum number of times a reward can be redeemed. If the limit is exceeded, the voucher creation fails.

**Why it matters**: Reward repetition limits are a business rule configured per reward, but the batch endpoint specification does not mention this check.

**Recommendation**: Document that each reward may have a maximum repetition limit per customer.

---

### 83. POST /vouchers/actions/gift-card-balance - Non-gift-card vouchers rejected

**Endpoint**: `POST /vouchers/actions/gift-card-balance`
**Specification file**: `paths/vouchers/VoucherGiftCardBalance.yaml`
**Controller**: `VouchersResourceControllerV1v0.class.php:452-460`

**What happens**: If the voucher is not a gift card (multi-purpose reward) type, the endpoint returns HTTP 400 with a detailed error message suggesting the integrator use GET /vouchers to verify the voucher's reward type.

**Why it matters**: The specification title mentions "Gift Card (Multi purpose reward)" but does not explicitly state that non-gift-card vouchers are rejected.

**Recommendation**: Add a note that only vouchers of the gift card (multi-purpose reward) type are accepted. Other voucher types return HTTP 400.

---

## Orders

### 84. POST /orders - Shipping address fields are silently trimmed

**Status**: Not important for integrators. Standard whitespace trimming on text input fields.

**Endpoint**: `POST /orders`
**Specification file**: `paths/orders/Orders.yaml`
**Controller**: `OrdersResourceControllerV1v0.class.php:193-226`

**What happens**: Before creating the order, the controller calls `tryFixInputStructureArguments` which trims whitespace from all shipping address fields: `address1` through `address7`, `zip`, `city`, and `country_code`. Leading and trailing whitespace is silently removed.

**Why it matters**: An integrator sending address fields with intentional formatting (such as trailing spaces used as padding) would find them modified without notice. More practically, an integrator who includes accidental whitespace would not receive a validation error but would see cleaned-up data in the response.

**Recommendation**: Document that shipping address fields (`address1` through `address7`, `zip`, `city`, `country_code`) are trimmed of leading and trailing whitespace before saving.

---

### 85. POST /orders - Order source is automatically set to "rest_api"

**Endpoint**: `POST /orders`
**Specification file**: `paths/orders/Orders.yaml`
**Controller**: `OrdersResourceControllerV1v0.class.php:167`

**What happens**: The order source is automatically set to the `rest_api` source identifier. This is a system-level value from `OrdersSourcesProvider`. The caller cannot specify or override the order source.

**Why it matters**: An integrator querying orders later will see a source field they did not set. If the integrator needs to distinguish between different integration channels, they cannot control this value.

**Recommendation**: Document that orders created via the API are automatically tagged with the source `rest_api`. This field cannot be set or overridden by the caller.

---

### 86. POST /orders - Non-existent customer returns 400, not 404

**Endpoint**: `POST /orders`
**Specification file**: `paths/orders/Orders.yaml`
**Controller**: `OrdersResourceControllerV1v0.class.php:152-156`

**What happens**: If the `customer_id` does not correspond to an existing customer, the endpoint returns HTTP 400 with reason `not_found` on the `customer_id` parameter, not HTTP 404.

**Why it matters**: An integrator would expect 404 for a non-existent resource referenced in the request. Receiving 400 with reason `not_found` as a parameter-level error is an unusual pattern.

**Recommendation**: Document that `customer_id` is validated against existing customer records. A non-existent customer returns HTTP 400 with reason `not_found` on the `customer_id` field.

---

### 87. GET /orders - Invalid customer_id returns empty results, not an error

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /orders`
**Specification file**: `paths/orders/Orders.yaml`
**Controller**: `OrdersResourceControllerV1v0.class.php:50-55`

**What happens**: If the `customer_id` query parameter contains an invalid (undecodable) value, the controller returns an empty result set with `total_items: 0` instead of returning HTTP 400.

**Why it matters**: An integrator passing a malformed `customer_id` would receive an empty list of orders rather than a validation error, making it difficult to distinguish between "no orders exist" and "the customer_id is invalid."

**Recommendation**: Document that an invalid `customer_id` value silently returns an empty result set rather than a validation error.

---

## Wallet

### 88. GET /wallet/points - Available points are scoped to API user's partner ACL

**Endpoint**: `GET /wallet/points`
**Specification file**: `paths/wallet/WalletPoints.yaml`
**Controller**: `WalletResourceControllerV1v0.class.php:78`, `CrmInterface.class.php:1919-1931`

**What happens**: The `available_points` value is not the customer's total available points. It is filtered by the partners accessible to the authenticated API user. An API user with access to only one partner will see only the points associated with that partner.

**Why it matters**: The specification describes `available_points` as "Amount of available points in the moment" without mentioning partner scoping. An integrator expecting the customer's total point balance would see a lower number if their API user account does not have access to all partners.

**Recommendation**: Document that `available_points` is scoped to the partners accessible to the authenticated API user. The value may be lower than the customer's total point balance if the API user does not have access to all partners.

---

### 89. GET /wallet/points - Money value is null when membership level disables point payment

**Endpoint**: `GET /wallet/points`
**Specification file**: `paths/wallet/WalletPoints.yaml`
**Controller**: `CrmInterface.class.php:1940-1957`

**What happens**: The `available_points_money_value` array entries have null `value` when the customer's membership level does not allow point payment. The money value is calculated per currency using the membership level's conversion rules.

**Why it matters**: The specification says "The calculation is available only if the customer status allows a point payment" but does not explain that the value will be null in the array entries, rather than the array being empty or the field being absent.

**Recommendation**: Clarify that when the customer's membership level does not allow point payment, the `value` field within each `available_points_money_value` entry is null rather than omitted.

---

### 90. GET /wallet/points-expiration - Expiration data is scoped to API user's partner ACL

**Endpoint**: `GET /wallet/points-expiration`
**Specification file**: `paths/wallet/WalletPointsExpiration.yaml`
**Controller**: `CrmInterface.class.php:1688-1711`

**What happens**: The `next_amount` and `next_date` values are calculated using partner ACL scoping. Points belonging to partners the API user cannot access are excluded from the expiration calculation.

**Why it matters**: The specification does not mention partner scoping. An API user with limited partner access may see different expiration amounts than an API user with full access, even for the same customer.

**Recommendation**: Document that point expiration data is scoped to the partners accessible to the authenticated API user.

---

### 91. GET /wallet/points-expiration - current_month_amount counts from now to month end, not the full month

**Endpoint**: `GET /wallet/points-expiration`
**Specification file**: `paths/wallet/WalletPointsExpiration.yaml`
**Controller**: `WalletResourceControllerV1v0.class.php:194-202`

**What happens**: The `current_month_amount` is calculated from the current moment to the last second of the current month. Points that already expired earlier in the month are not included.

**Why it matters**: The specification says "The amount of customer's points that will expire in current month." An integrator could interpret this as the total for the entire calendar month, but the actual value is the remaining amount that will still expire between now and month end.

**Recommendation**: Clarify that `current_month_amount` represents the amount of points that will expire between the current moment and the end of the current month, not the total that expired or will expire during the entire month.

---

### 92. GET /wallet/credits - Credits split by currency is restricted to API user's partner ACL

**Endpoint**: `GET /wallet/credits`
**Specification file**: `paths/wallet/WalletCredits.yaml`
**Controller**: `WalletResourceControllerV1v0.class.php:134`

**What happens**: The `split_by_currency` array contains only currencies associated with partners accessible to the authenticated API user. The totals (`earned_credits`, `redeemed_credits`, `available_credits`) at the top level are not partner-filtered, but the per-currency breakdown only includes currencies the API user can see.

**Why it matters**: An integrator comparing the sum of `split_by_currency` amounts against the top-level totals may find a mismatch if the API user does not have access to all partners and their currencies.

**Recommendation**: Document that `split_by_currency` is limited to currencies associated with partners accessible to the authenticated API user. The top-level credit totals may include amounts from currencies not represented in `split_by_currency`.

---

### 93. GET /wallet/credits - Invalid credit_type_id values are silently filtered

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /wallet/credits`
**Specification file**: `paths/wallet/WalletCredits.yaml`
**Controller**: `WalletResourceControllerV1v0.class.php:114-132`

**What happens**: The `credit_type_id` parameter accepts multiple values. Invalid IDs (those that cannot be decoded or do not correspond to an existing credit type) are silently skipped. If all provided IDs are invalid, the endpoint returns empty credit data instead of an error.

**Why it matters**: An integrator passing incorrect credit type IDs would receive an empty or reduced result set with no indication that their filter values were invalid.

**Recommendation**: Document that the `credit_type_id` filter silently ignores invalid or non-existent credit type IDs. If all provided IDs are invalid, the response contains empty credit data without an error.

---

### 94. GET /wallet/credits-expiration - Specification field descriptions are swapped and reference wrong resource

**Endpoint**: `GET /wallet/credits-expiration`
**Specification file**: `paths/wallet/WalletCreditsExpiration.yaml`
**Controller**: `WalletResourceControllerV1v0.class.php:215-229`

**What happens**: The specification field descriptions are incorrect: `next_amount` (a numeric field) has the description "Date (ISO 8601) when first points will expire", while `next_date` (a date field) has the description "Amount of redeemed points in time interval." The descriptions are swapped, and all three fields (`next_amount`, `next_date`, `current_month_amount`) reference "points" instead of "credits." The controller correctly sets the values.

**Why it matters**: The field descriptions are misleading: they are swapped relative to each other, and all three reference "points" instead of "credits." An integrator reading the specification would misinterpret which field contains the date and which contains the amount.

**Recommendation**: Fix the field descriptions: `next_amount` should describe the amount of credits expiring next, `next_date` should describe the date of the next credit expiration, and `current_month_amount` should reference credits instead of points.

---

## Products

### 95. GET /products - Invalid tag IDs are silently filtered

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /products`
**Specification file**: `paths/products/Products.yaml`
**Controller**: `ProductsResourceControllerV1v0.class.php:99-117`

**What happens**: The `tag_id[]` query parameter accepts multiple tag IDs. Invalid IDs (ones that cannot be decoded or do not correspond to an existing tag) are silently skipped. If all provided tag IDs are invalid, the endpoint returns an empty result set with no error.

**Why it matters**: An integrator passing an incorrect tag ID would receive an empty result set instead of an error, making it difficult to diagnose why no products are returned.

**Recommendation**: Document that the `tag_id[]` filter silently ignores invalid or non-existent tag IDs. If all provided IDs are invalid, the response is an empty list, not an error.

---

### 96. GET /products - Invalid partner_id returns empty results instead of error

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /products`
**Specification file**: `paths/products/Products.yaml`
**Controller**: `ProductsResourceControllerV1v0.class.php:86-91`

**What happens**: When `partner_id` cannot be decoded (invalid format), the controller returns an empty result set rather than HTTP 400. A valid but non-existent partner_id is passed through to the query and also returns empty results.

**Why it matters**: An integrator filtering products by an incorrectly formatted partner_id would receive an empty list rather than a validation error.

**Recommendation**: Document that an invalid `partner_id` format returns an empty result set rather than an error.

---

### 97. POST /products (batch) - Default partner auto-assigned from API user

**Endpoint**: `POST /products (batch)`
**Specification file**: `paths/products/ProductsBatch.yaml`
**Controller**: `ArticlesServices.class.php:1251-1258`

**What happens**: When `partner_id` is not provided in a batch product record, the system automatically assigns the first partner from the API user's restricted partners list.

**Why it matters**: The specification does not mention a partner_id default. An integrator omitting partner_id may not realize the product is being associated with a specific partner based on their API user's configuration.

**Recommendation**: Document that when `partner_id` is omitted, the system defaults to the first partner accessible to the authenticated API user.

---

### 98. POST /products (batch) - product_group_id and product_group_external_id cross-validation

**Status**: Solved. Already documented in `schemas/ProductBatch.yaml`. The field descriptions state that both parameters must represent the same product group (and the same product brand for the brand pair).

**Endpoint**: `POST /products (batch)`
**Specification file**: `paths/products/ProductsBatch.yaml`
**Controller**: `ArticlesServices.class.php:1089-1098`

**What happens**: When both `product_group_id` and `product_group_external_id` are provided, the system resolves each to a product group entity. If the two resolve to different product groups, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "Product groups found by id and external id are different." The same cross-validation applies to `product_brand_id` and `product_brand_external_id`.

**Why it matters**: The specification does not document this cross-validation. An integrator providing both fields expecting one to take precedence would receive an unexpected error.

**Recommendation**: Document that when both `product_group_id` and `product_group_external_id` are provided, they must resolve to the same product group. The same rule applies to `product_brand_id` and `product_brand_external_id`.

---

## Product Reservations

### 99. GET /product-reservations - external_reservation_code and external_reservation_list_type_id must be used together

**Endpoint**: `GET /product-reservations`
**Specification file**: `paths/products/ProductReservations.yaml`
**Controller**: `ProductReservationsResourceControllerV1v0.class.php:96-114`

**What happens**: If only one of `external_reservation_code` or `external_reservation_list_type_id` is provided (but not both), the endpoint returns HTTP 400 with reason `required` and the message "Both or none of above-mentioned query parameters have to be used."

**Why it matters**: The specification lists both parameters as optional but does not mention they are mutually dependent.

**Recommendation**: Document that `external_reservation_code` and `external_reservation_list_type_id` must be used together. Providing only one of them returns HTTP 400.

---

### 100. POST /product-reservations - total_price and currency_id are mutually required

**Status**: Solved. Already documented in `schemas/ProductReservation.yaml`. The field descriptions state that each is mandatory when the other is set.

**Endpoint**: `POST /product-reservations`
**Specification file**: `paths/products/ProductReservations.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2340-2356`

**What happens**: If `total_price` is provided without `currency_id` or vice versa, the endpoint returns HTTP 400 with reason `required` on the missing field. Both must be provided together, or both must be omitted.

**Why it matters**: The specification does not document this mutual dependency.

**Recommendation**: Document that `total_price` and `currency_id` must be provided together. If one is set, the other is required.

---

### 101. POST /product-reservations - External reservation code uniqueness enforced

**Endpoint**: `POST /product-reservations`
**Specification file**: `paths/products/ProductReservations.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2400-2413`

**What happens**: When external reservation codes are provided, each combination of `external_code_type_id` and `value` is checked against existing reservations. If a reservation with the same external code type and value already exists, the endpoint returns HTTP 400 with reason `relation_already_exists`.

**Why it matters**: This is an undocumented uniqueness constraint. An integrator retrying a reservation creation with the same external codes would receive an error if the first attempt succeeded.

**Recommendation**: Document that the combination of `external_code_type_id` and `value` must be unique across all product reservations. This can serve as an idempotency mechanism.

---

### 102. POST /product-reservations - Benefit codes are trimmed before validation

**Status**: Not important for integrators. Internal code format normalization that handles different code prefixes transparently.

**Endpoint**: `POST /product-reservations`
**Specification file**: `paths/products/ProductReservations.yaml`
**Controller**: `ProductReservationsResourceControllerV1v0.class.php:195-211`

**What happens**: Before processing, benefit codes are passed through a trimming function that removes prefixes or suffixes based on the voucher type prefix. Codes starting with PTV, catalog, or campaign prefixes are trimmed differently from regular voucher codes.

**Why it matters**: An integrator providing benefit codes with extra characters may not realize the code is being modified before validation.

**Recommendation**: Document that benefit codes are normalized before processing, and specify the expected code format.

---

### 103. POST /product-reservations - Voucher portability check for benefit codes

**Endpoint**: `POST /product-reservations`
**Specification file**: `paths/products/ProductReservations.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2438-2446`

**What happens**: When a benefit code references a voucher, the system checks whether the voucher is "portable" (transferable between customers). If the voucher is not portable and belongs to a different customer than the one on the reservation, the endpoint returns HTTP 400 with reason `not_belong_to_logged_in_customer`.

**Why it matters**: The specification does not mention voucher portability restrictions in the context of product reservations.

**Recommendation**: Document that non-portable vouchers can only be used as benefit codes for reservations belonging to the voucher's owner.

---

### 104. POST /product-reservations - Voucher validity and usage checks

**Endpoint**: `POST /product-reservations`
**Specification file**: `paths/products/ProductReservations.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2447-2458`

**What happens**: Each voucher-type benefit code is validated: expired vouchers, already-used vouchers, and vouchers already linked to another reservation are all rejected with HTTP 400.

**Why it matters**: The specification does not list the validation rules for benefit codes. An integrator would not know which conditions cause a benefit code to be rejected.

**Recommendation**: Document the benefit code validation rules: the voucher must be valid (not expired), must not have been used, and must not be linked to another reservation.

---

### 105. POST /product-reservations/actions/cancel - Cancellation refunds vouchers linked to benefit codes

**Endpoint**: `POST /product-reservations/actions/cancel`
**Specification file**: `paths/products/ProductReservationCancel.yaml`
**Controller**: `ProductReservationsServices.class.php:248-266`

**What happens**: When a reservation is cancelled, the system looks up the benefit codes stored as a property on the reservation. For each benefit code that references a voucher, if the voucher has not already been refunded, it is automatically refunded. The cancellation also registers an internal status-change event.

**Why it matters**: The specification says "Cancel an existing reservation" but does not mention that cancellation triggers voucher refunds and event registration.

**Recommendation**: Document that cancelling a reservation automatically refunds any vouchers linked to its benefit codes and registers an internal status-change event.

---

### 106. POST /product-reservations/actions/change-state - State 3 (Ready) is missing from the enum

**Endpoint**: `POST /product-reservations/actions/change-state`
**Specification file**: `paths/products/ProductReservationUpdateState.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:8394`

**What happens**: The specification's `state` enum includes values 0, 1, 2, 4, 5, 6, 7, and 8, but omits value 3. The description text includes "3 - Ready" in the list. The controller validates against the database, not the OpenAPI enum, so state 3 works in the implementation.

**Why it matters**: An integrator using code generation tools would not be able to set the state to "Ready" (3) because it is missing from the enum, even though the API accepts it.

**Recommendation**: Add value 3 to the `state` enum in the specification.

---

### 107. GET /reservable-products - partner_id filter accepted but not documented

**Endpoint**: `GET /reservable-products`
**Specification file**: `paths/products/ReservableProducts.yaml`
**Controller**: `ReservableProductsResourceControllerV1v0.class.php:93-94`

**What happens**: The controller accepts a `partner_id` query parameter and uses it to filter reservable products. This parameter is not listed in the specification's parameter list.

**Why it matters**: An integrator who needs to filter reservable products by partner has no documentation for this capability.

**Recommendation**: Add the `partner_id` query parameter to the GET /reservable-products specification.

---

### 108. POST /product-reservation-prices (batch) - Product can be identified by plu_ids as alternative to reservable_product_id

**Endpoint**: `POST /product-reservation-prices (batch)`
**Specification file**: `paths/products/ProductReservationPricesBatch.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:8422-8476`

**What happens**: The batch endpoint accepts `plu_ids` as an alternative to `reservable_product_id` for identifying the product. If `plu_ids` are provided instead of `reservable_product_id`, the system resolves the product by PLU codes first, then verifies it is a reservable product.

**Why it matters**: The specification schema references `ProductReservationPrice` which lists `reservable_product_id` but may not document `plu_ids` as an alternative.

**Recommendation**: Document that products in the batch can be identified either by `reservable_product_id` or by `plu_ids`. At least one of the two is required.

---

### 109. POST /product-reservation-prices (batch) - Upsert behavior matched by composite key

**Endpoint**: `POST /product-reservation-prices (batch)`
**Specification file**: `paths/products/ProductReservationPricesBatch.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:8578-8605`

**What happens**: If a price record already exists for the same combination of `reservable_product_id`, `store_id`, and `currency_id`, the existing record is updated with the new value. If no matching record exists, a new one is created.

**Why it matters**: The specification does mention upsert behavior but does not explain that the match is based on the three-field combination of product, store, and currency. An integrator may expect matching to be based on a price record ID rather than a composite key.

**Recommendation**: Expand the specification to explain that existing records are matched by the combination of `reservable_product_id`, `store_id`, and `currency_id`. A record with the same composite key is updated; otherwise a new record is created.

---

## Stamper

### 110. GET /stamper-campaigns - Partner ACL validation on partner_id filter

**Endpoint**: `GET /stamper-campaigns`
**Specification file**: `paths/stamper/StamperCampaigns.yaml`
**Controller**: `StamperCampaignsResourceControllerV1v0.class.php:120-134`

**What happens**: When the `partner_id` query parameter is provided, the system validates it against the authenticated API user's access control list. If the API user does not have access to the specified partner, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification lists `partner_id` as an optional query parameter but does not mention that it is ACL-restricted.

**Recommendation**: Document that the `partner_id` filter is validated against the authenticated API user's access control list. Only partners accessible to the API user can be used as a filter.

---

### 111. GET /stamper-cards - state parameter accepts only 0 or 1

**Endpoint**: `GET /stamper-cards`
**Specification file**: `paths/stamper/StamperCards.yaml`
**Controller**: `StamperCardsResourceControllerV1v0.class.php:162-171`

**What happens**: The `state` query parameter is validated before the query runs. Only values 0 and 1 are accepted. Any other integer value returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification references a reusable `card_state` parameter but does not document the validation constraint.

**Recommendation**: Document that the `state` parameter only accepts values 0 (inactive) and 1 (active). Other values return HTTP 400.

---

### 112. GET /stamper-cards and GET /stamper-stamps - Non-existent customer_id returns 400 instead of empty results

**Endpoint**: `GET /stamper-cards`, `GET /stamper-stamps`
**Specification file**: `paths/stamper/StamperCards.yaml`, `paths/stamper/StamperStamps.yaml`
**Controller**: `StamperCardsResourceControllerV1v0.class.php:131-142`, `StampsResourceControllerV1v0.class.php:131-142`

**What happens**: When the `customer_id` query parameter is provided, the system validates it against existing customer records. If the customer does not exist, the endpoint returns HTTP 400 with reason `not_found` instead of returning an empty result set.

**Why it matters**: Standard REST convention for list endpoints with filters is to return an empty collection when no results match. Returning HTTP 400 for a non-existent filter value is unexpected.

**Recommendation**: Document that `customer_id` is validated against existing customer records. If the customer does not exist, the endpoint returns HTTP 400 rather than an empty list.

---

## Segments

### 113. POST /segments - Segment auto-assigned to the "standard" segment group

**Endpoint**: `POST /segments`
**Specification file**: `paths/segments/Segments.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:3859-3874`, `SegmentsServices.class.php:96-107`

**What happens**: When a new segment is created, the system automatically assigns it to the project's "standard" segment group. The API request body does not accept a `segment_group_id` field. The default segment group is determined by the project's configuration.

**Why it matters**: The specification does not mention the segment group assignment. An integrator would not know that all segments created via the API are placed into the standard group, or that the group assignment cannot be controlled through the API.

**Recommendation**: Document that newly created segments are automatically assigned to the project's standard segment group. The segment group cannot be specified in the request.

---

### 114. PUT /segments/{segment_id} - Endpoint exists but is not in the specification

**Endpoint**: `PUT /segments/{segment_id}`
**Specification file**: `paths/segments/Segment.yaml` (only GET is defined)
**Controller**: `SegmentsResourceControllerV1v0.class.php:90-95`

**What happens**: The controller implements a PUT method that updates the segment's `name` and `note` fields. The `priority` field, even though it is accepted in the POST body, cannot be changed after creation. The specification file only defines the GET operation.

**Why it matters**: The PUT endpoint is functional in the implementation but completely absent from the specification. Integrators have no way to discover or use it.

**Recommendation**: Add the PUT operation to the specification. Document that only `name` and `note` can be updated. `priority` cannot be changed after creation.

---

### 115. POST /segments/{segment_id}/actions/add-customer - Operation is idempotent

**Endpoint**: `POST /segments/{segment_id}/actions/add-customer`
**Specification file**: `paths/segments/SegmentAddCustomer.yaml`
**Controller**: `SegmentsServices.class.php:269-271`

**What happens**: If the customer is already a member of the segment, the operation silently returns success (204 No Content) without creating a duplicate record or returning an error.

**Why it matters**: The specification does not mention that the operation is idempotent. An integrator may expect adding a customer who is already in the segment to return an error.

**Recommendation**: Document that the add-customer operation is idempotent. If the customer is already a member of the segment, the operation succeeds without error or duplicate record.

---

### 116. POST /segments/{segment_id}/actions/add-customer - Registers an internal event

**Endpoint**: `POST /segments/{segment_id}/actions/add-customer`
**Specification file**: `paths/segments/SegmentAddCustomer.yaml`
**Controller**: `SegmentsServices.class.php:293-295`

**What happens**: After successfully adding a customer to a segment, the system registers an internal "add account to segment" event. This event can trigger marketing automation workflows configured in CareCloud.

**Why it matters**: The specification does not mention this side effect. An integrator using segment membership changes as part of a workflow should know that adding a customer triggers an event.

**Recommendation**: Document that adding a customer to a segment triggers an internal event that may activate marketing automation workflows.

---

### 117. POST /segments/{segment_id}/actions/remove-customer - No error when customer is not in the segment

**Endpoint**: `POST /segments/{segment_id}/actions/remove-customer`
**Specification file**: `paths/segments/SegmentRemoveCustomer.yaml`
**Controller**: `SegmentsServices.class.php:231-241`

**What happens**: The remove operation performs a soft delete (sets `state=0`). If the customer is not in the segment, the operation returns 204 No Content without error (the UPDATE affects 0 rows, which is not treated as an error).

**Why it matters**: The specification does not mention this behavior. An integrator may expect removing a customer who is not in the segment to return an error.

**Recommendation**: Document that the remove-customer operation is a soft delete. If the customer is not in the segment, the operation succeeds without error (204 No Content).

---

## Statuses

### 118. GET /customers/{customer_id}/status-records - Auto-creates membership level record if none exists

**Endpoint**: `GET /customers/{customer_id}/status-records`
**Specification file**: Served by `StatusRecordsResourceControllerV1v0.class.php`
**Controller**: `CrmInterfaceIteratorsFactory.class.php:2574-2582`

**What happens**: When `customer_id` is provided as a filter, the system checks whether the customer has any currently valid membership level record. If no valid record exists, the system automatically creates one by calling `createMembershipLevelForAccount`. This is a write operation triggered by a GET request.

**Why it matters**: A GET endpoint should be read-only. An integrator reading status records may unknowingly cause the system to create a new membership level record for the customer.

**Recommendation**: Document that querying status records for a customer who has no currently valid membership level record may cause the system to automatically create one. This is not a read-only operation.

---

### 119. GET status records - Qualification turnover values are personalized per customer

**Endpoint**: `GET /customers/{customer_id}/status-records`
**Specification file**: `paths/statuses/Status.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:3750-3796`

**What happens**: When a status record is retrieved in the context of a specific customer, the `qualification_turnover` values are personalized. Instead of the generic qualification money amount configured for the status, the system calculates: (1) for the customer's current status, the turnover required to maintain that level, and (2) for the next status, the turnover required to reach it. A `due_date` field is also populated. Without a customer context, the generic configured values are returned.

**Why it matters**: The specification describes `qualification_turnover` as a static property of the status. An integrator comparing values from GET /statuses (generic) and the customer's status records endpoint (personalized) would see different values for the same status.

**Recommendation**: Document that `qualification_turnover` values in customer-specific status record responses are personalized. For the customer's current status, the value represents the remaining turnover needed to maintain the level. For the next status, it represents the turnover needed to reach it.

---

## Events

### 120. POST /events - event_type_id accepts text IDs as well as encoded IDs

**Endpoint**: `POST /events`
**Specification file**: `paths/events/Events.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:5020-5022`

**What happens**: The `event_type_id` field is resolved via `getActiveEventTypeByIdOrTextId()`. If the decoded value is an integer, the system looks up by numeric ID. If it is not an integer, it falls back to looking up by `text_id`. This means the field accepts both the standard encoded ID format and the event type's `text_id` string.

**Why it matters**: The specification describes `event_type_id` as "The unique ID of the event type" and shows a hex-encoded example. An integrator would not know they can pass the human-readable `text_id` directly.

**Recommendation**: Document that `event_type_id` accepts either the encoded event type ID or the event type's `text_id` string.

---

### 121. POST /events - state field is rejected if provided

**Endpoint**: `POST /events`
**Specification file**: `paths/events/Events.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:5087-5097`

**What happens**: If the `state` field is included in the event creation request body, the endpoint returns HTTP 400 with reason `not_allowed_value`. The state is system-managed and cannot be set during creation.

**Why it matters**: The Event schema includes a `state` field, and the POST description accepts the full Event schema. An integrator who includes `state` in the request body would receive an error with no prior warning.

**Recommendation**: Document that the `state` field cannot be set during event creation. It is managed by the system.

---

### 122. POST /events - created_at defaults to current timestamp

**Endpoint**: `POST /events`
**Specification file**: `paths/events/Events.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:5099-5114`

**What happens**: If `created_at` is not provided (null), the event timestamp defaults to the current server time. If provided, the value is validated as a valid timestamp format.

**Why it matters**: The specification says `created_at` is optional and shows a date format, but does not state what the default value is when omitted.

**Recommendation**: Document that when `created_at` is omitted, the event timestamp defaults to the current server time.

---

### 123. POST /events - Duplicate event type + customer + external ID combination is rejected

**Endpoint**: `POST /events`
**Specification file**: `paths/events/Events.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:5209-5219`

**What happens**: If an event with the same combination of `event_type_id`, `customer_id`, `external_id`, and `secondary_external_id` already exists, the endpoint returns HTTP 400 with reason `relation_already_exists`.

**Why it matters**: The specification does not mention any uniqueness constraint. An integrator retrying a failed event creation request with the same external IDs would receive this error if the first request actually succeeded.

**Recommendation**: Document that the combination of `event_type_id`, `customer_id`, `external_id`, and `secondary_external_id` must be unique. A duplicate combination returns HTTP 400 with reason `relation_already_exists`. This can serve as an idempotency mechanism.

---

### 124. POST /events - Required event properties enforced per event type

**Endpoint**: `POST /events`
**Specification file**: `paths/events/Events.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:5175-5191`

**What happens**: After validating individual property records, the system checks whether all required properties for the given event type have been included. If any required properties are missing, the endpoint returns HTTP 400 with reason `required` and lists the missing property IDs. Additionally, properties not associated with the event type are rejected with reason `not_found`.

**Why it matters**: The specification mentions `property_records` as an optional array but does not explain that certain event types require specific properties to be included.

**Recommendation**: Document that event types may have required properties. When creating an event, all required properties for the event type must be included in the `property_records` array. Use `GET /event-types/{event_type_id}/properties` to discover which properties are required.

---

## Campaigns

### 125. POST /campaigns - external_id must be unique

**Endpoint**: `POST /campaigns`
**Specification file**: `paths/campaigns/Campaigns.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2980-2991`

**What happens**: When `external_id` is provided, the system checks whether a campaign with the same `external_id` already exists. If it does, the endpoint returns HTTP 400 with reason `already_exists`.

**Why it matters**: The specification does not mention a uniqueness constraint on `external_id`.

**Recommendation**: Document that `external_id` must be unique across all campaigns. A duplicate value returns HTTP 400 with reason `already_exists`.

---

### 126. POST /campaigns - New campaign is always created in active state

**Endpoint**: `POST /campaigns`
**Specification file**: `paths/campaigns/Campaigns.yaml`
**Controller**: `CrmInterfaceForWebservice.class.php:2995`

**What happens**: Regardless of any `state` value in the request body, the campaign is always created with active state. The `state` field in the request body is ignored during creation.

**Why it matters**: An integrator who includes `state` expecting to create a campaign in a draft or inactive state would find it always created as active.

**Recommendation**: Document that new campaigns are always created in the active state. The `state` field in the request body is ignored during creation.

---

## Campaign Products

### 127. POST /campaign-products - value_type_id restricted to 1 or 2

**Endpoint**: `POST /campaign-products`
**Specification file**: `paths/campaigns/CampaignProducts.yaml`
**Controller**: `CampaignProductsResourceControllerV1v0.class.php:349-352`

**What happens**: The `value_type_id` field is validated to only accept values 1 (percentage discount) or 2 (final price). Any other value returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not document the allowed values for `value_type_id` as a validation rule.

**Recommendation**: Document that `value_type_id` must be either 1 (percentage discount) or 2 (final price). Other values are rejected.

---

### 128. POST /campaign-products - display_in values are validated against a closed set

**Endpoint**: `POST /campaign-products`
**Specification file**: `paths/campaigns/CampaignProducts.yaml`
**Controller**: `CampaignProductsResourceControllerV1v0.class.php:354-362`

**What happens**: Each value in the `display_in` array is validated against the list of possible campaign display locations. If any value is not in the allowed set, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not list the allowed display location values.

**Recommendation**: Document the allowed values for `display_in` or reference the endpoint that provides the list of valid display locations.

---

### 129. POST /campaign-products/{campaign_product_id}/campaign-product-store-records - campaign_product_id in body must match path

**Status**: Solved. Added a cross-validation note to the `campaign_product_id` field description in `schemas/CampaignProductStoreRecord.yaml`.

**Endpoint**: `POST /campaign-products/{campaign_product_id}/campaign-product-store-records`
**Specification file**: `paths/campaigns/SubCampaignProductStoreRecords.yaml`
**Controller**: `CampaignProductsResourceControllerV1v0.class.php:82-89`

**What happens**: The `campaign_product_id` in the request body must match the `campaign_product_id` in the URL path. If they differ, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not state this cross-validation rule.

**Recommendation**: Document that the `campaign_product_id` in the request body must match the path parameter. A mismatch returns HTTP 400.

---

## Messages

### 130. POST /messages/actions/send-message - Template must match the communication channel

**Status**: Solved. Added a cross-validation note to the `message_template_id` field description in `schemas/Message.yaml`.

**Endpoint**: `POST /messages/actions/send-message`
**Specification file**: `paths/messages/MessageSend.yaml`
**Controller**: `EcsInterfaceForWebservice.class.php:276-283`

**What happens**: The `message_template_id` must reference a template that belongs to the same `communication_channel_id` specified in the request. A channel mismatch returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not mention this cross-validation.

**Recommendation**: Document that the message template must be configured for the same communication channel specified in the request.

---

### 131. POST /messages/actions/send-message - Read-only fields are rejected

**Endpoint**: `POST /messages/actions/send-message`
**Specification file**: `paths/messages/MessageSend.yaml`
**Controller**: `EcsInterfaceForWebservice.class.php:285-327`

**What happens**: The endpoint rejects the following Message schema fields if they are included in the request: `message_id`, `status`, `send_time`, `opened_time`, `mail_client_user_agent`, and `mail_client_language`. Each one returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification accepts the full Message schema in the request body, implying all fields are writable.

**Recommendation**: Document which Message fields are accepted in the send request and which are read-only. Alternatively, use a separate schema for the send request that excludes the read-only fields.

---

### 132. POST /messages/actions/send-message - Attachments are email-only

**Endpoint**: `POST /messages/actions/send-message`
**Specification file**: `paths/messages/MessageSend.yaml`
**Controller**: `EcsInterfaceForWebservice.class.php:69-80`

**What happens**: If the request includes `attachments` and the communication channel is not email, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "Attachments can only be sent within the email communication channel."

**Why it matters**: The specification does not state that attachments are restricted to the email channel.

**Recommendation**: Document that the `attachments` field is only supported for the email communication channel. Including attachments with SMS or push notification channels returns HTTP 400.

---

### 133. POST /messages/actions/send-message - Missing consent returns 400, not silent skip

**Endpoint**: `POST /messages/actions/send-message`
**Specification file**: `paths/messages/MessageSend.yaml`
**Controller**: `EcsInterfaceForWebservice.class.php:199-207`

**What happens**: If the customer has not granted consent for the target communication channel, the endpoint returns HTTP 400 with reason `not_allowed_value` on `customer_id` and a message about missing consent.

**Why it matters**: The specification says consents are "checked" and if missing "the message is not sent" which could imply a silent skip (HTTP 204) rather than an explicit error.

**Recommendation**: Clarify that when the customer lacks consent for the target channel, the endpoint returns HTTP 400 with an error message, not a silent success.

---

### 134. POST /messages/actions/send-message - Contact format validated per channel

**Endpoint**: `POST /messages/actions/send-message`
**Specification file**: `paths/messages/MessageSend.yaml`
**Controller**: `EcsInterfaceForWebservice.class.php:123-173`

**What happens**: The `contact` field is validated based on the communication channel: for email, it must be a valid email format; for SMS, it must be a valid international phone number format. If `contact` is null, the system falls back to the customer's stored email (for email channel) or phone number (for SMS channel).

**Why it matters**: The specification says the `contact` field is for sending to "a different contact than customer has in database" but does not document the per-channel format validation or the fallback behavior.

**Recommendation**: Document that the `contact` field is validated based on the communication channel. When `contact` is omitted, the customer's stored email or phone number is used.

---

## Stores

### 135. GET /stores - Invalid reward_id silently returns empty results

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /stores`
**Specification file**: `paths/stores/Stores.yaml`
**Controller**: `StoresResourceControllerV1v0.class.php:82-85`

**What happens**: When a `reward_id` query parameter is provided but cannot be decoded, the controller silently returns an empty result set with `total_items: 0` instead of returning an error.

**Why it matters**: An integrator passing an invalid `reward_id` would receive an empty list instead of a validation error.

**Recommendation**: If `reward_id` is a supported filter, document it. Document that invalid encoded IDs for filter parameters silently return empty results instead of errors.

---

### 136. GET /stores - Undocumented filter matching behavior

**Endpoint**: `GET /stores`
**Specification file**: `paths/stores/Stores.yaml`
**Controller**: `StoresResourceControllerV1v0.class.php:100-106`

**What happens**: The controller accepts `description` and `short_description` query parameters and the `system_id` filter (mapped from `store_system_id`). The specification references these parameters but the endpoint description does not explain how they match (exact, partial, case-insensitive).

**Why it matters**: An integrator would need to experiment to determine the matching behavior.

**Recommendation**: Add a note to the endpoint description explaining the available filters and their matching behavior.

---

## Partners

### 137. GET /partners - Only active partners are returned

**Endpoint**: `GET /partners`
**Specification file**: `paths/partners/Partners.yaml`
**Controller**: `PartnersResourceControllerV1v0.class.php:146`

**What happens**: The list endpoint only returns active partners. Inactive partners are never included in the results.

**Why it matters**: The specification says "Get a list of partners" but does not mention that only active partners are returned. An integrator looking for a recently deactivated partner in the list would not find it.

**Recommendation**: Document that the GET /partners endpoint returns only active partners.

---

### 138. POST /customers/{customer_id}/partner-records - Partner ACL validation

**Endpoint**: `POST /customers/{customer_id}/partner-records`
**Specification file**: `paths/partners/SubPartnerProperties.yaml`
**Controller**: `PartnerRecordsResourceControllerV1v0.class.php:163-177`

**What happens**: When creating a partner record for a customer, the `partner_id` is validated against the authenticated API user's access control list. If the API user does not have access to the specified partner, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not mention that the partner_id must be accessible to the authenticated API user.

**Recommendation**: Document that the `partner_id` must be a partner the authenticated API user has access to.

---

## Users

### 139. GET /users - Phone number is validated with international prefix format

**Endpoint**: `GET /users`
**Specification file**: `paths/users/Users.yaml`
**Controller**: `UsersResourceControllerV1v0.class.php:110-121`

**What happens**: When the `phone` query parameter is provided, the value is validated against an international phone number format before being used as a filter. If the format is invalid, the endpoint returns HTTP 400 with reason `invalid_value_format`.

**Why it matters**: The specification lists `phone` as an optional filter but does not mention the format validation.

**Recommendation**: Document that the `phone` filter value must include the international prefix and conform to the international phone number format.

---

### 140. GET /users - Invalid store_id values are silently filtered

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /users`
**Specification file**: `paths/users/Users.yaml`
**Controller**: `UsersResourceControllerV1v0.class.php:80-101`

**What happens**: The `store_id` query parameter accepts multiple values. Invalid IDs are silently skipped. If all provided store IDs are invalid, the endpoint returns an empty result set.

**Why it matters**: An integrator passing an incorrect store ID would receive an empty result set or partial results without any error indicating the invalid ID.

**Recommendation**: Document that the `store_id` filter silently ignores invalid or non-existent store IDs.

---

### 141. POST /users/actions/login - Returns 200 or 201 depending on token state

**Endpoint**: `POST /users/actions/login`
**Specification file**: `paths/users/UserLogin.yaml`
**Controller**: `UsersResourceControllerV1v0.class.php:296-305`

**What happens**: The login endpoint returns HTTP 200 if the user already has a valid authentication token (reuses the existing token), or HTTP 201 if a new token was generated.

**Why it matters**: An integrator might not understand why the same successful login returns different HTTP status codes.

**Recommendation**: Document that HTTP 201 means a new authentication token was generated, while HTTP 200 means an existing valid token was returned.

---

### 142. POST /users/actions/login - Multiple failure handlers with different error types

**Endpoint**: `POST /users/actions/login`
**Specification file**: `paths/users/UserLogin.yaml`
**Controller**: `UsersResourceControllerV1v0.class.php:270-290`

**What happens**: The login process can fail with several distinct error conditions: inactivity period exceeded (HTTP 401), incorrect credentials (HTTP 401), expired partner license (HTTP 400), inactive partner (HTTP 400), exceeded failed login attempts (HTTP 400), expired password (HTTP 400), and no available login attempts (HTTP 400).

**Why it matters**: An integrator implementing error handling for the login flow would not know the full set of possible error responses.

**Recommendation**: Document the distinct login failure modes and their HTTP status codes.

---

### 143. POST /users/actions/login - login_stamp is updated on successful login

**Endpoint**: `POST /users/actions/login`
**Specification file**: `paths/users/UserLogin.yaml`
**Controller**: `UsersResourceControllerV1v0.class.php:261-268`

**What happens**: On successful login, the user's last login timestamp is updated and any failed login attempts are cleared. These are side effects of the login operation.

**Why it matters**: The specification describes the login as returning a bearer token but does not mention the side effects.

**Recommendation**: Document that a successful login updates the user's last login timestamp and clears any recorded failed login attempts.

---

### 144. POST /users/actions/logout - Invalid bearer_token returns 400 with reason not_found

**Endpoint**: `POST /users/actions/logout`
**Specification file**: `paths/users/UserLogout.yaml`
**Controller**: `UsersResourceControllerV1v0.class.php:340-347`

**What happens**: If the `bearer_token` does not correspond to a valid token in the system, the endpoint returns HTTP 400 with reason `not_found`. The token must be valid (not expired, not already invalidated).

**Why it matters**: The specification does not document what happens if the token is invalid or already expired.

**Recommendation**: Document that the `bearer_token` must be a valid, active token. If the token is not found or already invalidated, the endpoint returns HTTP 400.

---

### 145. POST /users/actions/sso-login - SSO response uses 200/201 but specification only documents 200

**Endpoint**: `POST /users/actions/sso-login`
**Specification file**: `paths/users/UserSsoLogin.yaml`
**Controller**: `UsersResourceControllerV1v0.class.php:402-411`

**What happens**: Like the regular login, the SSO login returns HTTP 200 when an existing token is reused and HTTP 201 when a new token is created. The specification only documents the 200 response.

**Why it matters**: The specification is missing the 201 response case.

**Recommendation**: Add a 201 response to the SSO login specification, following the same pattern as the regular user login endpoint.

---

## Tasks

### 146. GET /tasks - Invalid encoded IDs for filters silently return empty results

**Status**: Solved. Documented as a general filtering rule in the Filtering section of the API overview.

**Endpoint**: `GET /tasks`
**Specification file**: `paths/tasks/Tasks.yaml`
**Controller**: `TasksResourceControllerV1v0.class.php:98-106`

**What happens**: The `task_type_id`, `task_state_id`, `customer_id`, and `partner_id` query parameters are all validated through `areEncodedParametersValid`. If any of these IDs cannot be decoded, the endpoint silently returns an empty result set.

**Why it matters**: An integrator passing an incorrectly formatted ID would receive an empty list with no indication that the filter value was invalid.

**Recommendation**: Document that invalid encoded IDs for filter parameters result in an empty list, not a validation error.

---

### 147. GET /tasks - partner_id filter is accepted but not documented

**Endpoint**: `GET /tasks`
**Specification file**: `paths/tasks/Tasks.yaml`
**Controller**: `TasksResourceControllerV1v0.class.php:111`

**What happens**: The controller accepts a `partner_id` query parameter and uses it to filter tasks. The specification does not include `partner_id` in the parameter list.

**Why it matters**: An integrator who needs to filter tasks by partner would not know this filter exists.

**Recommendation**: Add `partner_id` as a documented query parameter for the GET /tasks endpoint.

---

## Tokens

### 148. POST /tokens - Virtual account auto-creation

**Endpoint**: `POST /tokens`
**Specification file**: `paths/tokens/Tokens.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:143-161`

**What happens**: When creating a token, if the external application has virtual accounts enabled, the system automatically creates a virtual (anonymous) customer account and links it to the token.

**Why it matters**: The specification describes token creation as creating "an authentication token for a client application installation" but does not mention the virtual account creation. An integrator tracking customer accounts would see new anonymous accounts appearing as a side effect.

**Recommendation**: Document that token creation may automatically create a virtual (anonymous) customer account if the external application is configured for virtual accounts.

---

### 149. POST /tokens - external_application_id must be a customer-type application

**Endpoint**: `POST /tokens`
**Specification file**: `paths/tokens/Tokens.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:103-111`

**What happens**: The `external_application_id` is validated against the external applications repository. If the application is not of the "customer" type, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "Only customer external application is allowed."

**Why it matters**: The specification describes `external_application_id` as "ID of the external application" without mentioning the type restriction.

**Recommendation**: Document that the `external_application_id` must refer to an external application of the customer type.

---

### 150. POST /tokens/{token_id}/actions/login - Already logged in returns 400

**Endpoint**: `POST /tokens/{token_id}/actions/login`
**Specification file**: `paths/tokens/TokenLogin.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:184-185`

**What happens**: If the token already has a customer logged in, the endpoint returns HTTP 400 with the message "Already logged in". The customer must first log out before logging in again.

**Why it matters**: The specification does not mention that the token must be in a logged-out state.

**Recommendation**: Document that the token must not already have a logged-in customer. Log out first before logging in a different customer.

---

### 151. POST /tokens/{token_id}/actions/login - Phone login requires project-level uniqueness

**Endpoint**: `POST /tokens/{token_id}/actions/login`
**Specification file**: `paths/tokens/TokenLogin.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:194-206`

**What happens**: When `login_type` is "phone", the system checks whether phone number uniqueness is enabled for the project. If not enabled, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification lists "phone" as a valid `login_type` enum value but does not mention that it may be disabled depending on project configuration.

**Recommendation**: Document that the "phone" login type is only available when the project has phone number uniqueness enabled.

---

### 152. POST /tokens/{token_id}/actions/login - Deleted or inactive customer returns 401

**Endpoint**: `POST /tokens/{token_id}/actions/login`
**Specification file**: `paths/tokens/TokenLogin.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:218-227`

**What happens**: After verifying the credentials, the controller checks the customer's account state. If the account state is not 1 (active), the endpoint returns HTTP 401. Deleted customers are treated the same as wrong credentials.

**Why it matters**: The specification does not mention account state validation. An integrator whose customer credentials are correct but whose account is inactive or deleted would receive a generic "invalid credentials" error.

**Recommendation**: Document that the customer account must be in active state. Inactive, deleted, or suspended accounts return HTTP 401 even if the credentials are correct.

---

### 153. POST /tokens/{token_id}/actions/logout - Already logged out returns 400

**Endpoint**: `POST /tokens/{token_id}/actions/logout`
**Specification file**: `paths/tokens/TokenLogout.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:300-302`

**What happens**: If the token does not have a logged-in customer, the endpoint returns HTTP 400 with the message "Already logged out". The logout operation is not idempotent.

**Why it matters**: An integrator calling logout multiple times would receive an error on the second call.

**Recommendation**: Document that the token must have a logged-in customer. Calling logout on a token with no logged-in customer returns HTTP 400.

---

### 154. POST /tokens/{token_id}/actions/social-login - Deleted account returns 401

**Endpoint**: `POST /tokens/{token_id}/actions/social-login`
**Specification file**: `paths/tokens/TokenSocialLogin.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:568-569`

**What happens**: After verifying the social network credentials, the controller checks whether the customer account is deleted. If deleted, it returns HTTP 401. The "already logged in" check also applies.

**Why it matters**: The specification does not mention that deleted accounts are rejected, or that the token must be in a logged-out state.

**Recommendation**: Document that social login checks for deleted accounts (returns 401) and requires the token to be in a logged-out state.

---

### 155. POST /tokens/{token_id}/actions/send-password-setup - Non-existent email silently succeeds

**Endpoint**: `POST /tokens/{token_id}/actions/send-password-setup`
**Specification file**: `paths/tokens/TokenSendPasswordSetup.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:483-484`, `523-527`

**What happens**: When the provided email or phone number does not match any existing customer account, the endpoint returns HTTP 204 (success) instead of an error. No message is sent, but the response gives no indication that the account was not found.

**Why it matters**: This is a security feature (prevents account enumeration), but the specification does not document it. An integrator may assume that HTTP 204 means the password setup message was sent successfully.

**Recommendation**: Document that the endpoint always returns HTTP 204 regardless of whether the email/phone matches an existing account. This prevents account enumeration.

---

### 156. POST /tokens/{token_id}/actions/send-password-setup - Phone with multiple accounts silently succeeds

**Endpoint**: `POST /tokens/{token_id}/actions/send-password-setup`
**Specification file**: `paths/tokens/TokenSendPasswordSetup.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:517-519`

**What happens**: When using a phone number as the recipient, if the phone number is associated with more than one customer account, the endpoint returns HTTP 204 without sending any message.

**Why it matters**: An integrator would not know that the password setup failed because of a non-unique phone number. The silent success response makes troubleshooting impossible.

**Recommendation**: Document that when using a phone number as the recipient, the password setup message is sent only if the phone number is associated with exactly one customer account. If the phone number matches multiple accounts, no message is sent but the endpoint still returns HTTP 204.

---

### 157. POST /tokens/{token_id}/actions/send-password-setup - Only email and SMS channels are supported

**Endpoint**: `POST /tokens/{token_id}/actions/send-password-setup`
**Specification file**: `paths/tokens/TokenSendPasswordSetup.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:457-469`

**What happens**: When using `communication_channel_id`, only email and SMS channel types are accepted. Other channel types return HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification describes `communication_channel_id` generically without listing which channel types are supported.

**Recommendation**: Document that only email and SMS communication channels are supported for password setup.

---

### 158. GET /tokens/{token_id}/actions/auth-token - Token must have a logged-in customer

**Endpoint**: `GET /tokens/{token_id}/actions/auth-token`
**Specification file**: `paths/tokens/TokenAuthentication.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:616-624`

**What happens**: If the token does not have a logged-in customer, the endpoint returns HTTP 400 with reason `not_allowed_value` and the message "Token has to be assigned to a customer."

**Why it matters**: The specification says "This endpoint returns an authentication token" for cross-application login but does not mention that the requesting token must have a logged-in customer.

**Recommendation**: Document that the token must have a logged-in customer to generate an authentication token.

---

### 159. POST /tokens/{token_id}/actions/test-customer-login - Test customer must exist in configuration

**Endpoint**: `POST /tokens/{token_id}/actions/test-customer-login`
**Specification file**: `paths/tokens/TokenTestCustomerLogin.yaml`
**Controller**: `TokensResourceControllerV1v0.class.php:719-722`

**What happens**: The test customer login retrieves a preconfigured test account from the CareCloud project. If no test account is configured, the endpoint returns HTTP 500 with the message "Testing customer was not found."

**Why it matters**: The specification describes this as "Login of a test customer account" but does not mention that a test account must be configured in the project.

**Recommendation**: Document that the project must have a test customer account configured. If no test account exists, the endpoint returns HTTP 500.

---

## Bookings

### 160. PUT /bookings/{booking_id} - Cancelled booking cannot be updated

**Endpoint**: `PUT /bookings/{booking_id}`
**Specification file**: `paths/bookings/Booking.yaml`
**Controller**: `BookingsResourceControllerV1v0.class.php:336-344`

**What happens**: If the booking's state is "deleted" (cancelled), the endpoint returns HTTP 400 with reason `deleted` and the message "An update of canceled booking is not possible."

**Why it matters**: The specification does not mention this restriction. An integrator attempting to reactivate a cancelled booking would receive an unexpected error.

**Recommendation**: Document that cancelled bookings cannot be updated.

---

### 161. POST /bookings/actions/average-booking-busy-times - booking_date cannot be in the past

**Endpoint**: `POST /bookings/actions/average-booking-busy-times`
**Specification file**: `paths/bookings/BookingBusyTimes.yaml`
**Controller**: `BookingsResourceControllerV1v0.class.php:450-459`

**What happens**: If the `booking_date` is in the past, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not mention the past-date restriction. An integrator might expect to retrieve historical busy-time data.

**Recommendation**: Document that `booking_date` must be today or a future date. Past dates are rejected.

---

### 162. DELETE /bookings/{booking_id} - Partner ACL filtering on deletion

**Endpoint**: `DELETE /bookings/{booking_id}`
**Specification file**: `paths/bookings/Booking.yaml`
**Controller**: `BookingsResourceControllerV1v0.class.php:296-301`

**What happens**: The delete operation passes the authenticated API user's partner access control list to the removal method. If the booking is associated with a partner that the API user does not have access to, the deletion is rejected.

**Why it matters**: The specification does not mention partner-based access restrictions on deletion.

**Recommendation**: Document that the booking can only be deleted if it belongs to a partner accessible to the authenticated API user.

---

### 163. GET /booking-tickets - valid_only cannot be combined with valid_from or valid_to

**Endpoint**: `GET /booking-tickets`
**Specification file**: `paths/bookings/BookingTickets.yaml`
**Controller**: `BookingTicketsResourceControllerV1v0.class.php:85-93`

**What happens**: If `valid_only` is set to `true` and either `valid_from` or `valid_to` is also provided, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification lists all three parameters as independent optional filters without mentioning this mutual exclusion.

**Recommendation**: Document that `valid_only` is mutually exclusive with `valid_from` and `valid_to`.

---

### 164. GET /booking-tickets - valid_from must be less than or equal to valid_to

**Endpoint**: `GET /booking-tickets`
**Specification file**: `paths/bookings/BookingTickets.yaml`
**Controller**: `BookingTicketsResourceControllerV1v0.class.php:94-104`

**What happens**: If both `valid_from` and `valid_to` are provided and `valid_from` is greater than `valid_to`, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not mention this validation constraint.

**Recommendation**: Document that `valid_from` must be less than or equal to `valid_to`.

---

### 165. GET /booking-tickets - Partner ACL filtering on results

**Endpoint**: `GET /booking-tickets`
**Specification file**: `paths/bookings/BookingTickets.yaml`
**Controller**: `BookingTicketsResourceControllerV1v0.class.php:124`

**What happens**: The booking ticket list is filtered by the authenticated API user's partner access control list. Only tickets associated with partners accessible to the API user are returned.

**Why it matters**: The specification does not mention partner-based access filtering.

**Recommendation**: Document that the booking ticket list is filtered by the API user's partner access.

---

## One-Time Password (OTP)

### 166. POST /one-time-password/actions/send - message_template must match communication_channel

**Status**: Solved. Added a cross-validation note to the `message_template_id` field description in `paths/otp/OTPSend.yaml`.

**Endpoint**: `POST /one-time-password/actions/send`
**Specification file**: `paths/otp/OTPSend.yaml`
**Controller**: `OneTimePasswordResourceControllerV1v0.class.php:65-73`

**What happens**: When `message_template_id` is provided, the system validates that the template's communication channel matches the `communication_channel_id` parameter. A mismatch returns HTTP 400.

**Why it matters**: The specification describes both fields independently without mentioning this cross-validation.

**Recommendation**: Document that when `message_template_id` is provided, its communication channel must match the `communication_channel_id` parameter.

---

### 167. POST /one-time-password/actions/send - Phone number is sanitized

**Status**: Solved. Added validation format documentation to the OTP `recipient` field description per communication channel, and added pattern constraints to the reusable `email` and `phone` query parameters in `parameters/_index.yaml` matching the patterns already in `PersonalInformation.yaml`.

**Endpoint**: `POST /one-time-password/actions/send`
**Specification file**: `paths/otp/OTPSend.yaml`
**Controller**: `OneTimePasswordResourceControllerV1v0.class.php:127`

**What happens**: When the communication channel is SMS, the phone number provided in the `recipient` field is validated against an international prefix format and then sanitized. Empty phone numbers are rejected with reason `empty`, and invalid formats with reason `not_allowed_value`.

**Why it matters**: The specification describes `recipient` generically without mentioning phone format requirements or sanitization.

**Recommendation**: Document that when the communication channel is SMS, the recipient must be a valid phone number in international prefix format. The phone number is sanitized before sending.

---

### 168. POST /one-time-password/actions/send - SMS uses project default template when not specified

**Endpoint**: `POST /one-time-password/actions/send`
**Specification file**: `paths/otp/OTPSend.yaml`
**Controller**: `OneTimePasswordResourceControllerV1v0.class.php:129-136`

**What happens**: When the communication channel is SMS and `message_template_id` is not provided, the system falls back to a default SMS template from the project configuration.

**Why it matters**: The specification mentions a default but does not differentiate between email and SMS defaults.

**Recommendation**: Expand the `message_template_id` description to note that the default template source differs by communication channel and is project-configurable.

---

### 169. POST /one-time-password/actions/send - Template configuration error returns 403

**Endpoint**: `POST /one-time-password/actions/send`
**Specification file**: `paths/otp/OTPSend.yaml`
**Controller**: `OneTimePasswordResourceControllerV1v0.class.php:162-166`

**What happens**: If the template has a configuration issue, the endpoint returns HTTP 403 Forbidden with a message about template setup.

**Why it matters**: The specification does not document a 403 response. An integrator receiving a 403 when they have valid credentials would not expect it to be a template configuration problem.

**Recommendation**: Document that HTTP 403 can be returned when the message template configuration is invalid.

---

### 170. POST /one-time-password/actions/send - Only email and SMS channels are supported

**Endpoint**: `POST /one-time-password/actions/send`
**Specification file**: `paths/otp/OTPSend.yaml`
**Controller**: `OneTimePasswordResourceControllerV1v0.class.php:154-161`

**What happens**: The controller only handles email and SMS communication channels. Any other channel ID (including 4 and 5, which are listed in the specification's enum) returns HTTP 400.

**Why it matters**: The specification enum lists values 1, 2, 4, and 5 as possible values, but the implementation only supports 1 (email) and 2 (SMS).

**Recommendation**: Either correct the specification enum to list only 1 and 2, or document that only email and SMS channels are currently supported for OTP sending.

---

## Related Customers

### 171. POST /customers/{customer_id}/related-customers - Self-reference rejected

**Endpoint**: `POST /customers/{customer_id}/related-customers`
**Specification file**: `paths/customers/SubCustomerRelatedCustomers.yaml`
**Controller**: `RelatedCustomersResourceControllerV1v0.class.php:214-222`

**What happens**: If the `customer_id` path parameter is the same as the `related_customer_id` in the request body, the endpoint returns HTTP 400 with reason `not_allowed_value`.

**Why it matters**: The specification does not mention this restriction.

**Recommendation**: Document that a customer cannot be related to themselves. The `related_customer_id` must be different from the path `customer_id`.

---

### 172. POST /customers/{customer_id}/related-customers - is_leading determines role assignment

**Endpoint**: `POST /customers/{customer_id}/related-customers`
**Specification file**: `paths/customers/SubCustomerRelatedCustomers.yaml`
**Controller**: `RelatedCustomersResourceControllerV1v0.class.php:225-233`

**What happens**: The `is_leading` field determines which customer is the "master" and which is the "subordinate" in the relationship. When `is_leading` is true, the related customer becomes the master.

**Why it matters**: The specification says `is_leading` indicates "if related customer is a leader in their relationship" but does not explain that this controls the internal master/subordinate assignment.

**Recommendation**: Clarify that `is_leading` controls the direction of the relationship and affects how the relationship appears in queries.

---

### 173. DELETE /customers/{customer_id}/related-customers/{customer_relation_id} - Relation must belong to the customer

**Endpoint**: `DELETE /customers/{customer_id}/related-customers/{customer_relation_id}`
**Specification file**: `paths/customers/SubCustomerRelatedCustomer.yaml`
**Controller**: `RelatedCustomersResourceControllerV1v0.class.php:286-294`

**What happens**: The controller validates that the specified customer_id is either the master or subordinate in that relationship. If the customer is not a party to the relation, the endpoint returns HTTP 400.

**Why it matters**: An integrator might expect that any valid `customer_relation_id` can be deleted regardless of which `customer_id` is in the path.

**Recommendation**: Document that the customer_relation_id must refer to a relation where the path customer_id is one of the parties.

---

## Recommendation Engine

### 174. POST /recommendation-engine/shopping-cart/actions/order - customer_id is not required

**Endpoint**: `POST /recommendation-engine/shopping-cart/actions/order`
**Specification file**: `paths/recommendations/RecommendationCartOrder.yaml`
**Controller**: `RecommendationEngineResourceControllerV1v0.class.php:52-57`

**What happens**: For the shopping-cart algorithm with the "order" method, `customer_id` is not required. The order endpoint passes `null` as customer_id to the recommendation engine. For all other algorithm/method combinations, `customer_id` is required.

**Why it matters**: The specification does not explain why `customer_id` is absent for this endpoint while other recommendation endpoints require it.

**Recommendation**: Document that `customer_id` is optional because this method recommends based on cart contents alone, without personalisation from the customer's purchase history.

---

### 175. Recommendation engine - Empty response instead of error when recommendations unavailable

**Endpoint**: `POST /recommendation-engine/{algorithm}/actions/{method}`
**Specification file**: Various under `paths/recommendations/`
**Controller**: `RecommendationEngineResourceControllerV1v0.class.php:107-109,119-121,131-133`

**What happens**: When the recommendation engine cannot compute recommendations, the endpoint returns an empty success response (HTTP 200 with empty content) rather than an error code.

**Why it matters**: An integrator expecting always a list of products or an error would receive a successful response with no products, which is ambiguous.

**Recommendation**: Document that when the recommendation engine cannot compute results, the endpoint returns an empty result set rather than an error.

---

## Referrals

### 180. GET /referrals - Non-existent customer_id returns 400 instead of empty results

**Endpoint**: `GET /referrals`
**Specification file**: `paths/referrals/Referrals.yaml`
**Controller**: `ReferralsResourceControllerV1v0.class.php:52-59`

**What happens**: The endpoint validates the `customer_id` query parameter against the database by calling `getAccountByIdcont`. If the customer does not exist, the endpoint returns HTTP 400 with reason `not_found` instead of returning an empty result set.

**Why it matters**: The general filtering rule across the API is that a filter referencing a non-existent resource returns an empty result set, not an error. This endpoint breaks that rule for `customer_id`. The behavior is inconsistent with most other list endpoints (for example GET /purchases, GET /vouchers, GET /events), which return empty results for a non-existent `customer_id`.

**Recommendation**: Document the validation behavior, or align the endpoint with the general filtering rule.

---

## Interest Records

### 176. POST /customers/{customer_id}/interest-records - customer_id in body must match path

**Status**: Solved. Added a cross-validation note to the `customer_id` field description in `schemas/InterestRecord.yaml`.

**Endpoint**: `POST /customers/{customer_id}/interest-records`
**Specification file**: `paths/customers/SubCustomerInterests.yaml`
**Controller**: `InterestRecordsResourceControllerV1v0.class.php:162-173`

**What happens**: When the interest record body contains a `customer_id` and the path also provides a `customer_id`, the controller checks that both values match. If they differ, the request is rejected.

**Why it matters**: The specification does not document this cross-validation.

**Recommendation**: Document that if the request body contains a `customer_id`, it must match the `customer_id` path parameter.

---

## External Applications

### 177. GET /customer-external-applications - CareCloud internal application excluded

**Endpoint**: `GET /customer-external-applications`, `GET /user-external-applications`
**Specification file**: External application specification files
**Controller**: `ExternalApplicationsResourceControllerV1v0.class.php:78,105`

**What happens**: Both the list endpoint and the single-resource endpoint apply a filter that excludes the internal CareCloud application. This application is never returned in API responses, even if its ID is known.

**Why it matters**: An integrator who discovers this application ID through other means would not be able to retrieve it via the API.

**Recommendation**: Document that the internal CareCloud application is excluded from API responses and cannot be retrieved.

---

## Audiences

### 178. GET /audiences - ACL-restricted by user

**Endpoint**: `GET /audiences`, `GET /audiences/{audience_id}`
**Specification file**: `paths/audiences/Audiences.yaml`, `paths/audiences/Audience.yaml`
**Controller**: `AudiencesResourceControllerV1v0.class.php:64,104-105`

**What happens**: Both the list and detail endpoints filter audiences by the authenticated API user's access control list. An audience the user cannot access returns 404 for the detail endpoint or is excluded from the list.

**Why it matters**: The specification does not mention user-level access filtering on audiences.

**Recommendation**: Document that audiences are filtered by the API user's access permissions. Only audiences accessible to the authenticated user are returned.

---

## Customer Engagement

### 179. POST/PUT /customer-engagement-containers/setups - Required fields not marked in schema

**Endpoint**: `POST /customer-engagement-containers/setups`, `PUT /customer-engagement-containers/setups/{customer_engagement_container_id}`
**Specification file**: `paths/customer_engagement/Setup.yaml`, `paths/customer_engagement/Setups.yaml`
**Controller**: `CustomerEngagementContainersResourceControllerV1V0.class.php:181-248`

**What happens**: The POST endpoint validates that `name` and `application_url` are both non-empty. If either is null or empty, the endpoint returns HTTP 400 with reason `required`. The PUT endpoint additionally requires `state` to be non-null.

**Why it matters**: The specification schema may not mark these fields as required. An integrator omitting `application_url` or `state` would receive an unexpected "required" error.

**Recommendation**: Document that `name` and `application_url` are required for both POST and PUT. Additionally, `state` is required for PUT.

---

## Similarity groups

Cross-cutting patterns identified across findings. Used to batch scope decisions: when a group of findings shares the same behavioral pattern, the user reviews the group and marks individual findings as out of scope if the pattern is not important for integration documentation. Findings marked with **Status**: Out of scope carry a reference back to their group.

### Group 1: Invalid filter IDs silently return empty results

GET (list) endpoints that silently return an empty result set when a query parameter contains an invalid or non-existent ID, instead of returning HTTP 400. The integrator cannot distinguish "no data matches" from "the filter value was malformed."

Findings (solved): 57, 87, 93, 95, 96, 135, 140, 146. Documented as a general filtering rule in the Filtering section of the API overview.

Exceptions that return 400 instead (not yet resolved): 44, 112, 180, 181

### Group 2: Partner ACL validation and scoping

Endpoints that validate or filter data based on the authenticated API user's partner access control list. Either the request is rejected when the partner is not accessible, or the response data is silently scoped to accessible partners only.

Findings: 46, 56, 88, 90, 92, 110, 138, 162, 165, 178

### Group 3: Internal events and marketing automation side effects

Write operations that register an internal event as a side effect. These events can trigger marketing automation workflows configured in CareCloud. The event registration is non-blocking (failure does not affect the primary operation).

Findings: 47, 59, 116

### Group 4: Auto-generation and auto-detection of field values

The system automatically generates, detects, or defaults a field value when the caller does not provide one. The integrator may not expect the field to be populated on read-back.

Findings: 2, 3, 4, 15, 85, 113, 122

### Group 5: Input normalization (trimming, lowercasing, sanitizing)

Input values are silently modified before processing: whitespace trimming, case normalization, character stripping, or format sanitization. The stored or matched value differs from what the integrator sent.

Findings (resolved): 6, 65, 70, 84, 102, 167. Findings 6, 65, 70, 84, 102 are standard internal processing not important for integrators. Finding 167 solved by documenting validation format in the OTP recipient description and adding pattern constraints to the email and phone query parameters.

### Group 6: Deleted or inactive resource handling (400 instead of 404)

Endpoints that return HTTP 400 (or 401) instead of HTTP 404 or 410 when the target resource exists in the database but is in a deleted or inactive state.

Findings: 8, 16, 18, 22, 72, 152, 154

### Group 7: Date range validation (from must be less than or equal to to)

Endpoints that reject requests where a start date is after an end date. A logically obvious constraint, but not documented in the specification.

Findings: 13, 68, 164

### Group 8: Membership level restrictions on operations

Operations that check whether the customer's current membership level (status) permits the action (point collection, credit usage). If the membership level does not allow it, the operation is rejected.

Findings: 36, 45, 50, 54

### Group 9: Uniqueness constraints and idempotency keys

Fields with server-enforced uniqueness. A duplicate value returns HTTP 400. These constraints can also serve as idempotency mechanisms for retried requests.

Findings: 26, 41, 101, 123, 125

### Group 10: Insufficient balance and positive amount validation

Operations that validate the requested amount against the customer's available balance (points, credits) or reject zero/negative amounts. The validation prevents overdraft and ensures meaningful transactions.

Findings: 33, 39, 40, 42, 49, 52, 53, 58, 81

### Group 11: Cross-validation between parameters

Endpoints that validate consistency between two or more request fields (body vs. path, or two body fields). A mismatch returns HTTP 400.

Findings (solved): 28, 98, 100, 129, 130, 166, 176. Each cross-validation rule was documented in the relevant field description. Findings 98 and 100 were already documented before this session.

### Group 12: Read-only or system-managed fields rejected when provided

Fields that are present in the schema but cannot be set by the caller. Including them in a create or update request returns HTTP 400 or the value is silently ignored.

Findings: 5, 10, 121, 126, 131

### Group 13: Undocumented query parameters

Query parameters that the controller accepts and uses for filtering, but that are not listed in the specification's parameter definitions.

Findings: 107, 147

### Group 14: Credit balance recalculation mechanics

Internal mechanics of how credit balances are recalculated after deposit, reduction, or transfer operations. Details about record-level recomputation and expiry-ordered consumption.

Findings: 48, 55

### Group 15: Reward eligibility restrictions

Business rules that restrict which customers can redeem a reward or which reward types can be used for voucher creation. Includes segment restrictions, repetition limits, reward state checks, and reward type restrictions.

Findings: 60, 61, 62, 63, 80, 82

## Summary

| Endpoint group | Findings | Count |
|---|---|---|
| **Customers** | | |
| POST /customers | 1, 2, 3, 4, 5, 6 | 6 |
| PUT /customers | 7, 8, 9, 10 | 4 |
| DELETE /customers | 11 | 1 |
| POST /customers/actions/set-status-record | 12, 13 | 2 |
| POST /customers/actions/newsletters-sign-up | 14, 15 | 2 |
| POST /customers/actions/verify-credentials | 16 | 1 |
| **Cards** | | |
| PUT /cards/{card_id} | 17 | 1 |
| POST /cards/actions/assign-free-card | 18, 19 | 2 |
| POST /cards/actions/generate-digital-card-file | 20 | 1 |
| POST /cards/actions/generate-passmachine-card | 21, 22 | 2 |
| POST /cards/actions/validate-free-card | 23 | 1 |
| POST /cards/actions/validate-isic-card | 24 | 1 |
| **Purchases** | | |
| PUT /purchases/{purchase_id} | 25 | 1 |
| POST /purchases/actions/send-purchase | 26, 27, 28, 29, 30, 31 | 6 |
| POST /purchases/actions/assign-customer | 32 | 1 |
| POST /purchases/actions/accept-payment | 33, 34 | 2 |
| **Points** | | |
| POST /points/actions/assign-points | 35 | 1 |
| POST /points/actions/synchronize-points | 36, 37, 38 | 3 |
| POST /points/actions/transfer-points | 39, 40 | 2 |
| POST /point-reservations/actions/reserve-points | 41, 42 | 2 |
| POST /point-reservations/actions/free-points | 43 | 1 |
| GET /point-history | 44 | 1 |
| **Credits** | | |
| POST /credits/actions/deposit | 45, 46, 47, 48 | 4 |
| POST /credits/actions/reduce | 49, 50, 51 | 3 |
| POST /credits/actions/transfer | 52, 53, 54, 55 | 4 |
| GET /credit-history | 56 | 1 |
| GET /credits | 57 | 1 |
| **Rewards** | | |
| POST /rewards/{reward_id}/actions/create-voucher | 58, 59, 60, 61, 62, 63 | 6 |
| POST /rewards/{reward_id}/actions/create-custom-voucher | 64 | 1 |
| GET /rewards | 65, 66, 181 | 3 |
| POST /rewards/actions/create-simple-reward | 67, 68, 69 | 3 |
| **Vouchers** | | |
| GET /vouchers | 70, 71 | 2 |
| DELETE /vouchers/{voucher_id} | 72, 73, 74 | 3 |
| PUT /vouchers/{voucher_id} | 75, 76, 77 | 3 |
| POST /vouchers/{voucher_id}/actions/apply | 78, 79 | 2 |
| POST /vouchers/batch | 80, 81, 82 | 3 |
| POST /vouchers/actions/gift-card-balance | 83 | 1 |
| **Orders** | | |
| POST /orders | 84, 85, 86 | 3 |
| GET /orders | 87 | 1 |
| **Wallet** | | |
| GET /wallet/points | 88, 89 | 2 |
| GET /wallet/points-expiration | 90, 91 | 2 |
| GET /wallet/credits | 92, 93 | 2 |
| GET /wallet/credits-expiration | 94 | 1 |
| **Products** | | |
| GET /products | 95, 96 | 2 |
| POST /products (batch) | 97, 98 | 2 |
| **Product Reservations** | | |
| GET /product-reservations | 99 | 1 |
| POST /product-reservations | 100, 101, 102, 103, 104 | 5 |
| POST /product-reservations/actions/cancel | 105 | 1 |
| POST /product-reservations/actions/change-state | 106 | 1 |
| GET /reservable-products | 107 | 1 |
| POST /product-reservation-prices (batch) | 108, 109 | 2 |
| **Stamper** | | |
| GET /stamper-campaigns | 110 | 1 |
| GET /stamper-cards | 111, 112 | 2 |
| **Segments** | | |
| POST /segments | 113 | 1 |
| PUT /segments/{segment_id} | 114 | 1 |
| POST /segments/{segment_id}/actions/add-customer | 115, 116 | 2 |
| POST /segments/{segment_id}/actions/remove-customer | 117 | 1 |
| **Statuses** | | |
| GET /customers/{customer_id}/status-records | 118, 119 | 2 |
| **Events** | | |
| POST /events | 120, 121, 122, 123, 124 | 5 |
| **Campaigns** | | |
| POST /campaigns | 125, 126 | 2 |
| **Campaign Products** | | |
| POST /campaign-products | 127, 128 | 2 |
| POST /campaign-products/{id}/campaign-product-store-records | 129 | 1 |
| **Messages** | | |
| POST /messages/actions/send-message | 130, 131, 132, 133, 134 | 5 |
| **Stores** | | |
| GET /stores | 135, 136 | 2 |
| **Partners** | | |
| GET /partners | 137 | 1 |
| POST /customers/{customer_id}/partner-records | 138 | 1 |
| **Users** | | |
| GET /users | 139, 140 | 2 |
| POST /users/actions/login | 141, 142, 143 | 3 |
| POST /users/actions/logout | 144 | 1 |
| POST /users/actions/sso-login | 145 | 1 |
| **Tasks** | | |
| GET /tasks | 146, 147 | 2 |
| **Tokens** | | |
| POST /tokens | 148, 149 | 2 |
| POST /tokens/{token_id}/actions/login | 150, 151, 152 | 3 |
| POST /tokens/{token_id}/actions/logout | 153 | 1 |
| POST /tokens/{token_id}/actions/social-login | 154 | 1 |
| POST /tokens/{token_id}/actions/send-password-setup | 155, 156, 157 | 3 |
| GET /tokens/{token_id}/actions/auth-token | 158 | 1 |
| POST /tokens/{token_id}/actions/test-customer-login | 159 | 1 |
| **Bookings** | | |
| PUT /bookings/{booking_id} | 160 | 1 |
| POST /bookings/actions/average-booking-busy-times | 161 | 1 |
| DELETE /bookings/{booking_id} | 162 | 1 |
| GET /booking-tickets | 163, 164, 165 | 3 |
| **OTP** | | |
| POST /one-time-password/actions/send | 166, 167, 168, 169, 170 | 5 |
| **Related Customers** | | |
| POST /customers/{customer_id}/related-customers | 171, 172 | 2 |
| DELETE /customers/{customer_id}/related-customers/{id} | 173 | 1 |
| **Recommendation Engine** | | |
| POST /recommendation-engine/shopping-cart/actions/order | 174 | 1 |
| POST /recommendation-engine/{algorithm}/actions/{method} | 175 | 1 |
| **Referrals** | | |
| GET /referrals | 180 | 1 |
| **Interest Records** | | |
| POST /customers/{customer_id}/interest-records | 176 | 1 |
| **External Applications** | | |
| GET /customer-external-applications | 177 | 1 |
| **Audiences** | | |
| GET /audiences | 178 | 1 |
| **Customer Engagement** | | |
| POST/PUT /customer-engagement-containers/setups | 179 | 1 |
| **Total** | | **181** |

## Scope

This report covers all major endpoint groups across the CareCloud REST API. A total of 46 controllers were analyzed in depth.

**Analyzed groups**: Customers, Cards, Purchases, Points, Credits, Rewards, Vouchers, Orders, Wallet, Products, Product Reservations, Stamper, Segments, Statuses, Events, Campaigns, Campaign Products, Messages, Stores, Partners, Users, Tasks, Tokens, Bookings, OTP, Related Customers, Recommendation Engine, Referrals, Interest Records, External Applications, Audiences, Customer Engagement.

## Not analyzed

The following 31 controllers were not analyzed. Each entry lists the controller, its size, and the reason it was skipped.

### May contain undocumented business logic (candidates for future analysis)

| Controller | Lines | Reason not analyzed |
|---|---|---|
| WebOverlaysContainers | 380 | Customer engagement overlay management. Largest uncovered controller. May contain validation rules or state management logic worth documenting. |
| Agreements | 137 | Customer agreement/consent management. May contain consent validation rules, agreement versioning, or state-dependent behavior. |
| PropertyRecords | 170 | Customer property value CRUD. May contain data type validation, membership level restrictions (similar to finding 10 in Customers), or value format enforcement. |
| CustomerProperties | 130 | Customer property definitions. May contain property type restrictions or configuration-dependent validation. |
| PointReservations (list/detail) | 169 | List and detail endpoints for point reservations. The action endpoints (reserve, free) are already covered (findings 41-43). The list/detail controller may contain partner ACL filtering or state-based filtering. |
| PointsPurchases | 123 | Points-to-purchases relationship mapping. May contain partner ACL scoping similar to other points endpoints. |
| CardTypes | 185 | Card type management. May contain validation rules for card type creation/update or state restrictions. |
| Monitoring | 183 | System monitoring endpoint. May contain health check logic or status reporting that integrators should know about. |
| Currencies | 136 | Currency management. May contain activation/deactivation rules or partner-scoped behavior. |
| RewardProducts | 114 | Reward-product associations. May contain validation rules linking rewards to specific products. |
| RewardProperties | 131 | Reward property records. May contain data type validation or required-property enforcement similar to event properties (finding 124). |
| PurchaseProperties | 118 | Purchase property definitions. May contain property type restrictions. |
| PurchaseItems | 102 | Purchase item list/detail. May contain partner ACL filtering. |
| Interests | 122 | Interest definitions (list/detail). May contain partner or customer scoping. |

### Read-only reference data (very unlikely to contain undocumented behavior)

These controllers serve static lookup/reference data. They are typically under 120 lines, implement only GET list and GET detail operations, and contain no business logic beyond basic pagination and filtering.

| Controller | Lines | Content |
|---|---|---|
| Countries | 82 | Country reference data (ISO codes, names). Read-only. |
| Languages | 101 | Language reference data. Read-only. |
| CommunicationChannels | 125 | Communication channel definitions (email, SMS, push). Read-only. |
| CustomerAddressTypes | 123 | Address type definitions. Read-only. |
| CustomerRelationTypes | 111 | Customer relation type definitions. Read-only. |
| CustomerTypes | 110 | Customer type definitions. Read-only. |
| CreditTypes | 119 | Credit type definitions. Read-only. |
| PointTypes | 110 | Point type definitions. Read-only. |
| PurchaseTypes | 98 | Purchase type definitions. Read-only. |
| PurchaseItemTypes | 101 | Purchase item type definitions. Read-only. |
| PurchaseItemProperties | 111 | Purchase item property definitions. Read-only. |
| RewardTypes | 114 | Reward type definitions. Read-only. |
| RewardProductGroups | 82 | Reward-product-group associations. Read-only. |
| RewardProductBrands | 80 | Reward-product-brand associations. Read-only. |
| Dictionaries | 59 | Dictionary/lookup values. Read-only. |
| Services | 24 | Service reference data. Read-only, minimal controller. |
| Tests | 41 | Test/health check endpoint. Internal tooling, not a business resource. |
