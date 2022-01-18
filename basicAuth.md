## HTTP Basic autentication
HTTP Basic authentication method (https://en.wikipedia.org/wiki/Basic_access_authentication) has to be used to login to API successfully. There are two options to authenticate depending on your kind of integration:

-   Enterprise interface authentication  (credentials are necessary to access the data )
-   Customer interface authentication  (mobile/web app integration with partial free access to data)

### Enterprise interface authentication

<p class="warning">HTTP BASIC authentication is deprecated for the Enterprise interface. Please look at HTTP Bearer authentification for the Enterprise interface.</p>

User name and password have to be used for Enterprise interface authentication. Credentials are BASE64 encoded during HTTP basic authentication. HTTP header will look like the example below.

Before BASE64 encoding:

```http request
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Basic <user name>:<password>
```

After BASE64 encoding:

```http request
Content-Type: application/json
Accept-Language: cs, en-gb;q=0.8
Authorization: Basic Zm9vOmJhcg==
```

The password is composed of two parts:

-   User password hashed with MD5 algorithm
-   Time in format YYYYMMDDHH (UTC)

All parts are connected and hashed with SHA-256 algorithm (implementation in PHP):

```http request
hash('sha256',md5("password")."2019040112");
```

Result:

```http request
string(64) "c0c0d92061deb13bf34570e513229368979708efcdbc80b8d881e7ef03461a6c"
```

### Customer interface authentication

1. Get `<user name>` from your account manager. It is usually `customer_interface` for the customer interface, but it might be different depending on the project.<br/>
2. Create a token using the method  [[POST] /tokens](#operation/postToken).
   The creation of a token is different from other API calls.  HTTP Authorization header contains only a login name and no token (because it doesn't exist yet).
```http request
<user name>:
 ```
Value of HTTP header Authentication contains BASE64 encoded string `<user name>:`. The request looks like this:

```http request
POST <projectURL>/webservice/rest-api/customer-interface/v1.0/tokens
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