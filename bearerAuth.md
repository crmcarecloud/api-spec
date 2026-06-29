HTTP Bearer authentication. The default authentication scheme for both the Enterprise interface and the Customer interface.

**Enterprise interface.** Obtain a token by calling [POST /users/actions/login](https://carecloud.readme.io/reference/postuserlogin) with the username and password issued by your CareCloud account manager. Send the token on every subsequent request as `Authorization: Bearer <token>`.

**Customer interface.** Obtain a token by calling [POST /tokens](https://carecloud.readme.io/reference/posttoken). Send the token on every subsequent request as `Authorization: Bearer <token>`.

For the full authentication flow, see [Authentication](https://carecloud.readme.io/reference/authentication) on the documentation portal.
