// Keycloak always adds typ and sid to the ID token. The FAPI 2.0 Security Profile
// conformance tests warn about both because neither is a claim the client requested
// or one they know. Only realm-fapi2-sp-final.json uses this mapper.
token.type(null);
token.setSessionId(null);
