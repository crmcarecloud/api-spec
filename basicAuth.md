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

User name and token (provided by resource tokens) are used for Customer interface client authentication. Credentials are BASE64 encoded. HTTP header will look like the example below.

Before BASE64 encoding:

```http request
GET / HTTP/1.1
Host: project.carecloud.cz
Authorization: Basic <user name>:69dfa909171f15783d92877d86d114f8c49a50a8e15bdf4c280ba46cdb3a3d49c1288218
```

After BASE64 encoding:

```http request
GET / HTTP/1.1
Host: project.carecloud.cz
Authorization: Basic Zm9vOmJhcg==
```