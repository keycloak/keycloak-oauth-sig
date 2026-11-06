// Keycloak always adds typ to the ID token. The OpenID Connect conformance tests warn
// about it because it is not a claim the client requested or one they know.
// Only realm-oidc.json uses this mapper.
token.type(null);
