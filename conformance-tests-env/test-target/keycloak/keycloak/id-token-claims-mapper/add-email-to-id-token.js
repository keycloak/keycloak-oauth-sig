// OpenID Connect Core 5.4: the claims of the email scope are returned in the ID token
// only when no access token is issued, that is for response_type=id_token. Otherwise
// they are returned from the userinfo endpoint. Only realm-oidc.json uses this mapper.
var client = realm.getClientByClientId(token.getIssuedFor());
var clientSession = userSession.getAuthenticatedClientSessionByClient(client.getId());
if (clientSession != null && "id_token".equals(clientSession.getNote("response_type"))) {
    token.setEmail(user.getEmail());
    token.setEmailVerified(user.isEmailVerified());
}
