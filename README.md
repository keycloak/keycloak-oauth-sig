# OAuth SIG (OAuth : Special Interest Group)

Ex FAPI-SIG (Financial-grade API Security : Special Interest Group)

## Overview

FAPI-SIG is a group whose activity is mainly supporting [Financial-grade API (FAPI)](https://openid.net/wg/fapi/) and its related specifications to keycloak.

FAPI-SIG is open to everybody so that anyone can join it anytime. Nothing special need not to be done to join it. Who want to join it can only access to the communication channels shown below.  All of its activities and outputs are public so that anyone can access them.

FAPI-SIG mainly treats FAPI and its related specifications but not limited to. E.g., Ecosystems employing FAPI for their API Security like UK OpenBanking, Open Banking Brasil and Australia Consumer Data Right (CDR).

Since June 2023, FAPI-SIG is evolved into OAuth SIG. OAuth SIG will mainly treats OAuth/OIDC and its related security features like FAPI 2.0 to Keycloak.

## Scope

Supporting OAuth/OIDC and its related security features to Keycloak.

## Roles

Tech Lead : [Takashi Norimatsu](https://github.com/tnorimat)

## Members

Please refer to [the list](./members.adoc).

## Goals

Currently, proposed goals are as follows.

### OAuth and OIDC related security features

- [OAuth 2.0 Rich Authorization Requests (RAR)](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-rar)

- [OpenID for Verifiable Credential Issuance](https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0.html)

### Nation/Region/Market Specific Features

- EU : PSD2/eIDAS - QWAC Verification Extension

## Open Works

Currently, proposed open works are as follows.

- Integrating FAPI conformance tests run into keycloak’s CI/CD pipeline

- Implement security profiles for Apps run on mobile devices
  - [RFC 8252 OAuth 2.0 for Native Apps](https://tools.ietf.org/html/rfc8252)
  - [OAuth 2.0 for Browser-Based Apps](https://tools.ietf.org/html/draft-ietf-oauth-browser-based-apps-06)

- [FAPI-RW App2App](https://openid.net/2020/06/23/openid-foundation-announces-fapi-rw-app2app-certification-launched/)

## Contributions

FAPI related accomplishments by FAPI-SIG and OAuth SIG, other contributors and keycloak development team is as follows.​

### Common Security Features

#### keycloak 14
 - [Client Policies](https://www.keycloak.org/docs/latest/release_notes/index.html#client-policies-and-financial-grade-api-fapi-support)​

#### keycloak 24

 - [Lightweight Access Token](https://www.keycloak.org/docs/latest/release_notes/index.html#lightweight-access-tokens-support)
 - [OAuth Grant Type SPI](https://www.keycloak.org/docs/latest/release_notes/index.html#oauth-grant-type-spi)

### Nation/Region/Market Specific Features

#### keycloak 15
 - [Brazil : Open Banking Brasil Financial-grade API Security Profile](https://www.keycloak.org/docs/latest/release_notes/index.html#financial-grade-api-fapi-improvements-fapi-ciba-and-open-banking-brasil) 
   
   mainly by keycloak development team.

### Standards​

#### keycloak 13

  - [Client Initiated Backchannel Authentication (CIBA) poll mode​](https://www.keycloak.org/docs/latest/release_notes/index.html#openid-connect-client-initiated-backchannel-authentication-ciba)

#### keycloak 14

  - [FAPI 1.0 Baseline Security Profile](https://www.keycloak.org/docs/latest/release_notes/index.html#client-policies-and-financial-grade-api-fapi-support)​
  - [FAPI 1.0 Advanced Security Profile​](https://www.keycloak.org/docs/latest/release_notes/index.html#client-policies-and-financial-grade-api-fapi-support)

#### keycloak 15

  - [Client Initiated Backchannel Authentication (CIBA) ping mode​](https://www.keycloak.org/docs/latest/release_notes/index.html#financial-grade-api-fapi-improvements-fapi-ciba-and-open-banking-brasil)

    mainly by keycloak development team.

  - [FAPI JWT Secured Authorization Response Mode for OAuth 2.0 (JARM)​](https://www.keycloak.org/docs/latest/release_notes/index.html#highlights)

    mainly by the contributor outside FAPI-SIG.

  - [FAPI Client Initiated Backchannel Authentication Profile (FAPI-CIBA)​](https://www.keycloak.org/docs/latest/release_notes/index.html#financial-grade-api-fapi-improvements-fapi-ciba-and-open-banking-brasil)

  - [RFC 9126 OAuth 2.0 Pushed Authorization Requests (PAR)](https://datatracker.ietf.org/doc/html/rfc9126)

#### keycloak 18

  - [OpenID Connect Logout 1.0 for Logout Profiles](https://www.keycloak.org/docs/latest/release_notes/index.html#openid-connect-logout-improvements)

    mainly by keycloak development team and the contributor outside FAPI-SIG.

#### keycloak 20

  - UK OpenBanking​ Security Profile

#### keycloak 23
  - [RFC 9207 OAuth 2.0 Authorization Server Issuer Identification](https://datatracker.ietf.org/doc/html/rfc9207)
  - [RFC 9449 OAuth 2.0 Demonstrating Proof of Possession (DPoP)](https://datatracker.ietf.org/doc/html/rfc9449)
  - [FAPI 2.0 Security Profile Second Implementer’s Draft](https://openid.net/specs/fapi-2_0-security-profile-ID2.html)
  - [FAPI 2.0 Message Signing First Implementer’s Draft](https://openid.bitbucket.io/fapi/fapi-2_0-message-signing.html)

#### keycloak 24

  - [RFC 8032 Edwards-Curve Digital Signature Algorithm (EdDSA)](https://datatracker.ietf.org/doc/html/rfc8032)
  - [The OAuth 2.1 Authorization Framework - Draft version 10](https://www.ietf.org/archive/id/draft-ietf-oauth-v2-1-10.html)

#### keycloak 25

  - [OpenID for Verifiable Credential Issuance](https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0.html)

#### Keycloak 26

  - [Initiating User Registration via OpenID Connect 1.0](https://openid.net/specs/openid-connect-prompt-create-1_0.html)
  - [FAPI 2.0 Security Profile Final](https://openid.net/specs/fapi-security-profile-2_0-final.html)
  - [FAPI 2.0 Message Signing Final](https://openid.net/specs/fapi-message-signing-2_0-final.html)

#### In progress

##### OpenID for Verifiable Credentials

###### Format

  - [Selective Disclosure for JWTs (SD-JWT)](https://drafts.oauth.net/oauth-selective-disclosure-jwt/draft-ietf-oauth-selective-disclosure-jwt)
  - [SD-JWT-based Verifiable Credentials (SD-JWT VC)](https://drafts.oauth.net/oauth-sd-jwt-vc/draft-ietf-oauth-sd-jwt-vc.html)
  - [JWT VC](https://identity.foundation/jwt-vc-presentation-profile/#jwt-vc)
  - [W3C Verfiable Credentials Data Format(VCDM)](https://www.w3.org/TR/vc-data-model/)

###### Issuance Protocol

  - [OpenID for Verifiable Credential Issuance](https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0.html)

##### Other OpenID Connect Extension

  - [OpenID Connect for Identity Assurance 1.0](https://openid.net/specs/openid-connect-4-identity-assurance-1_0-13.html)

### Automated Conformance Test Run Environment by this kc-fapi-sig repository

The current environment uses the following software version.
- Keycloak 26.6.2
- Conformance-suite version : release-v5.1.43

#### FAPI 1.0 Advanced (Final)​
  - Client Authentication Method : MTLS, private_key_jwt​
  - Signature Algorithm : PS256, ES256​
  - Request Object Method : plain, PAR​
  - Response Mode : plain, JARM​

Keycloak 15.0.2 have achieved [certification for all 8 conformance profiles of FAPI 1 Advanced Final (Generic)](https://openid.net/certification/#FAPI_OPs).


#### FAPI-CIBA (Implementer’s Draft)​
  - Client Authentication Method : MTLS, private_key_jwt​
  - Signature Algorithm : PS256, ES256​
  - Mode : Poll, Ping

Keycloak 15.0.2 have achieved [certification for all 4 conformance profiles of Financial-grade API Client Initiated Backchannel Authentication Profile (FAPI-CIBA)](https://openid.net/certification/#FAPI-CIBA_OPs).

#### Open Banking Brasil FAPI 1.0
  - Client Authentication Method : MTLS, private_key_jwt​
  - Signature Algorithm : PS256
  - Request Object Method : plain, PAR​
  - Response Mode : plain, JARM​

Keycloak 15.0.2 have achieved [certification for 8 conformance profiles of Brazil Open Banking (Based on FAPI 1 Advanced Final)](https://openid.net/certification/#FAPI_OPs) except for DCR (Dynamic Client Registration).

#### Open Finance Brasil FAPI 1.0 (Open Banking Brasil FAPI 1.0 was evolved)
  - Client Authentication Method : private_key_jwt​
  - Signature Algorithm : PS256
  - Request Object Method : PAR​
  - Response Mode : plain
  - ID token encryption : required

#### Australia Consumer Data Right (CDR)
  - Client Authentication Method : private_key_jwt​
  - Signature Algorithm : PS256
  - Request Object Method : plain, PAR​
  - Response Mode : plain, JARM​

Keycloak 15.0.2 have achieved [certification for all 2 conformance profiles of Australia CDR (Based on FAPI 1 Advanced Final)](https://openid.net/certification/#FAPI_OPs).

#### UK Open Banking
  - Client Authentication Method : MTLS, private_key_jwt​
  - Signature Algorithm : PS256
  - Request Object Method : plain, PAR​
  - Response Mode : plain

#### OpenID Connect: OpenID Providers
  - Basic OP
  - Implicit OP
  - Hybrid OP
  - Config OP
  - Dynamic OP
  - Form Post OP
  - 3rd Party-Init OP

Keycloak 18.0.0 have re-achieved [certification for 6 conformance profiles of Certified OpenID Providers](https://openid.net/certification/#OPs) except for 3rd Party-Init OP.

#### OpenID Connect: OpenID Providers for Logout Profile
  - Front-Channel OP
  - Back-Channel OP
  - Session OP
  - RP-Initiated OP

Keycloak 18.0.0 have achieved [certification for all 4 conformance profiles of Certified OpenID Providers for Logout Profiles](https://openid.net/certification/#OPs).

Note: Session OP and Front-Channel OP of OpenID Provider for Logout Profile conformance tests cannot be automated. These can be passed manually.

#### FAPI 2.0 Security Profile Second Implementer’s Draft
  - FAPI2SP MTLS + MTLS
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP private key + MTLS
    - Client Authentication Method : private_key_jwt
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP OpenID Connect
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : openid
    - FAPI Profile : plain​
  - FAPI2SP MTLS + DPoP
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP private key + DPoP
    - Client Authentication Method : private_key_jwt
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP OpenID Connect (DPoP)
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : openid
    - FAPI Profile : plain​

#### FAPI 2.0 Message Signing First Implementer’s Draft
  - FAPI2MS JAR
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : plain_response
  - FAPI2MS JARM
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : jarm
  - FAPI2MS JAR (DPoP)
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : plain_response
  - FAPI2MS JARM (DPoP)
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : jarm

#### FAPI 2.0 Security Profile (Final)
  - FAPI2SP MTLS + MTLS
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP private key + MTLS
    - Client Authentication Method : private_key_jwt
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP OpenID Connect
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : openid
    - FAPI Profile : plain​
  - FAPI2SP MTLS + DPoP
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP private key + DPoP
    - Client Authentication Method : private_key_jwt
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
  - FAPI2SP OpenID Connect (DPoP)
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : openid
    - FAPI Profile : plain​

#### FAPI 2.0 Message Signing (Final)
  - FAPI2MS JAR
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : plain_response
  - FAPI2MS JARM
    - Client Authentication Method : mtls
    - Sender Constrain : mtls
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : jarm
  - FAPI2MS JAR (DPoP)
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : plain_response
  - FAPI2MS JARM (DPoP)
    - Client Authentication Method : mtls
    - Sender Constrain : dpop
    - OpenID : plain_oauth
    - FAPI Profile : plain​
    - FAPI Request Method : signed_non_repudiation
    - FAPI Response Mode : jarm

### Passed Conformance Tests per Keycloak version

To ensure that every keycloak version can pass conformance tests, we check if a new Keycloak version pass conformance tests that the older Keycloak version could pass whenever the new Keycloak version is released.

We tagged the environment for every keycloak verion:
|Tag|Keycloak version|Conformance-suite version|
|---|----------------|-------------------------|
|kc-15.0.2|15.0.2|release-v4.1.38|
|kc-17.0.0|17.0.0|release-v4.1.41|
|kc-17.0.1|17.0.1|release-v4.1.41|
|kc-18.0.0|18.0.0|release-v4.1.42|
|kc-18.0.2|18.0.2|release-v4.1.42|
|kc-19.0.1|19.0.1|release-v4.1.45|
|kc-19.0.2|19.0.2|release-v5.0.3|
|kc-20.0.0|20.0.0|release-v5.0.6|
|kc-20.0.1|20.0.1|release-v5.0.6|
|kc-20.0.2|20.0.2|release-v5.0.7|
|kc-20.0.3|20.0.3|release-v5.0.12|
|kc-20.0.5|20.0.5|release-v5.0.14|
|kc-21.0.0|21.0.0|release-v5.1.0|
|kc-21.0.1|21.0.1|release-v5.1.0|
|kc-21.0.2|21.0.2|release-v5.1.2|
|kc-21.1.0|21.1.0|release-v5.1.2|
|kc-21.1.1|21.1.1|release-v5.1.2|
|kc-21.1.2|21.1.2|release-v5.1.5|
|kc-22.0.0|22.0.0|release-v5.1.5|
|kc-22.0.1|22.0.1|release-v5.1.5|
|kc-22.0.2|22.0.2|release-v5.1.5|
|kc-22.0.3|22.0.3|release-v5.1.7|
|kc-22.0.4|22.0.4|release-v5.1.8|
|kc-22.0.5|22.0.5|release-v5.1.9|
|kc-23.0.0|23.0.0|release-v5.1.15|
|kc-23.0.1|23.0.1|release-v5.1.15|
|kc-23.0.2|23.0.2|release-v5.1.15|
|kc-23.0.3|23.0.3|release-v5.1.15|
|kc-23.0.4|23.0.4|release-v5.1.15|
|kc-23.0.5|23.0.5|release-v5.1.15|
|kc-23.0.6|23.0.6|release-v5.1.15|
|kc-23.0.7|23.0.7|release-v5.1.15|
|kc-24.0.0|24.0.0|release-v5.1.15|
|kc-24.0.1|24.0.1|release-v5.1.15|
|kc-24.0.2|24.0.2|release-v5.1.16|
|kc-24.0.3|24.0.3|release-v5.1.16|
|kc-24.0.4|24.0.4|release-v5.1.16|
|kc-24.0.5|24.0.5|release-v5.1.16|
|kc-25.0.0|25.0.0|release-v5.1.17|
|kc-25.0.1|25.0.1|release-v5.1.17|
|kc-25.0.2|25.0.2|release-v5.1.17|
|kc-25.0.4|25.0.4|release-v5.1.21|
|kc-25.0.5|25.0.5|release-v5.1.22|
|kc-25.0.6|25.0.6|release-v5.1.22|
|kc-26.0.0|26.0.0|release-v5.1.22|
|kc-26.0.1|26.0.1|release-v5.1.22|
|kc-26.0.2|26.0.2|release-v5.1.22|
|kc-26.0.4|26.0.4|release-v5.1.22|
|kc-26.0.5|26.0.5|release-v5.1.22|
|kc-26.0.6|26.0.6|release-v5.1.25|
|kc-26.0.7|26.0.7|release-v5.1.26|
|kc-26.0.8|26.0.8|release-v5.1.28|
|kc-26.1.0|26.1.0|release-v5.1.29|
|kc-26.1.1|26.1.1|release-v5.1.30|
|kc-26.1.2|26.1.2|release-v5.1.30|
|kc-26.1.3|26.1.3|release-v5.1.30|
|kc-26.1.4|26.1.4|release-v5.1.30|
|kc-26.1.5|26.1.5|release-v5.1.31|
|kc-26.2.0|26.2.0|release-v5.1.31|
|kc-26.2.1|26.2.1|release-v5.1.31|
|kc-26.2.2|26.2.2|release-v5.1.31|
|kc-26.2.3|26.2.3|release-v5.1.31|
|kc-26.2.4|26.2.4|release-v5.1.31|
|kc-26.2.5|26.2.5|release-v5.1.32|
|kc-26.3.0|26.3.0|release-v5.1.33|
|kc-26.3.1|26.3.1|release-v5.1.33|
|kc-26.3.2|26.3.2|release-v5.1.33|
|kc-26.3.3|26.3.3|release-v5.1.36|
|kc-26.3.4|26.3.4|release-v5.1.36|
|kc-26.3.5|26.3.5|release-v5.1.36|
|kc-26.4.0|26.4.0|release-v5.1.36|
|kc-26.4.1|26.4.1|release-v5.1.37|
|kc-26.4.2|26.4.2|release-v5.1.37|
|kc-26.4.4|26.4.4|release-v5.1.37|
|kc-26.4.5|26.4.5|release-v5.1.37|
|kc-26.4.6|26.4.6|release-v5.1.37|
|kc-26.4.7|26.4.7|release-v5.1.37|
|kc-26.5.0|26.5.0|release-v5.1.39|
|kc-26.5.1|26.5.1|release-v5.1.39|
|kc-26.5.2|26.5.2|release-v5.1.39|
|kc-26.5.3|26.5.3|release-v5.1.39|
|kc-26.5.4|26.5.4|release-v5.1.39|
|kc-26.5.5|26.5.5|release-v5.1.39|
|kc-26.5.6|26.5.6|release-v5.1.39|
|kc-26.5.7|26.5.7|release-v5.1.41|
|kc-26.6.0|26.6.0|release-v5.1.41|
|kc-26.6.1|26.6.1|release-v5.1.41|
|kc-26.6.2|26.6.2|release-v5.1.43|

|Keycloak version|FAPI 1.0 Advanced|FAPI-CIBA|Open Banking Brasil FAPI 1.0 (\*1,\*2),\*15|Open Finance Brasil FAPI 1.0 (\*3)|Australia Consumer Data Right (CDR) (\*8)|UK Open Banking|OpenID Connect OP (\*4)|OpenID Connect OP for Logout Profile|FAPI 2.0 Security Profile Implementer’s Draft (\*6,\*14)|FAPI 2.0 Message Signing Implementer’s Draft (\*6,\*14)|FAPI 2.0 Security Profile (\*9)|FAPI 2.0 Message Signing (\*9)|
|-|-|-|-|-|-|-|-|-|-|-|-|-|
|15.0.2|x|x|x|-|x|-|-|-|-|-|-|-|
|17.0.0|x|x|x|-|x|-|-|-|-|-|-|-|
|17.0.0-legacy|x|x|x|-|x|-|-|-|-|-|-|-|
|17.0.1|x|x|x|-|x|-|-|-|-|-|-|-|
|17.0.1-legacy|x|x|x|-|x|-|-|-|-|-|-|-|
|18.0.0|x|x|x|-|x|-|x|x|-|-|-|-|
|18.0.0-legacy|x|x|x|-|x|-|x|x|-|-|-|-|
|18.0.2|x|x|x|-|x|-|x|x|-|-|-|-|
|18.0.2-legacy|x|x|x|-|x|-|x|x|-|-|-|-|
|19.0.1|x|x|x|-|x|-|x|x|-|-|-|-|
|19.0.1-legacy|x|x|x|-|x|-|x|x|-|-|-|-|
|19.0.2|x|x|x|-|x|-|x|x|-|-|-|-|
|19.0.2-legacy|x|x|x|-|x|-|x|x|-|-|-|-|
|20.0.0|x|x|x|-|x|x|x|x|-|-|-|-|
|20.0.1|x|x|x|-|x|x|x|x|-|-|-|-|
|20.0.2|x|x|x|-|x|x|x|x|-|-|-|-|
|20.0.3|x|x|x|-|x|x|x|x|-|-|-|-|
|20.0.5|x|x|x|-|x|x|x|x|-|-|-|-|
|21.0.0|x|x|x|-|x|x|x|x|-|-|-|-|
|21.0.1|x|x|x|-|x|x|x|x|-|-|-|-|
|21.0.2|x|x|x|-|x|x|x|x|-|-|-|-|
|21.1.0|x|x|x|-|x|x|x|x|-|-|-|-|
|21.1.1|x|x|x|-|x|x|x|x|-|-|-|-|
|21.1.2|x|x|x|-|x|x|x|x|-|-|-|-|
|22.0.0|x|x|x|-|x|x|x|x|-|-|-|-|
|22.0.1|x|x|x|-|x|x|x|x|-|-|-|-|
|22.0.2|x|x|x|-|x|x|x|x|-|-|-|-|
|22.0.3|x|x|x|-|x|x|x|x|-|-|-|-|
|22.0.4|x|x|x|-|x|x|x|x|-|-|-|-|
|22.0.5|x|x|x|-|x|x|x|x|-|-|-|-|
|23.0.0|x|x|-(*5)|-(*5)|x|x|x|x|x|x|-|-|
|23.0.1|x|x|x|x|x|x|x|x|x|x|-|-|
|23.0.2|x|x|x|x|x|x|x|x|x|x|-|-|
|23.0.3|x|x|x|x|x|x|x|x|x|x|-|-|
|23.0.4|x|x|x|x|x|x|x|x|x|x|-|-|
|23.0.5|x|x|x|x|x|x|x|x|x|x|-|-|
|23.0.6|x|x|x|x|x|x|x|x|x|x|-|-|
|23.0.7|x|x|x|x|x|x|x|x|x|x|-|-|
|24.0.0|x|x|x|x|x|x|x|x|x|x|-|-|
|24.0.1|x|x|x|x|x|x|x|x|x|x|-|-|
|24.0.2|x|x|x|x|x|x|x|x|x|x|-|-|
|24.0.3|x|x|x|x|x|x|x|x|x|x|-|-|
|24.0.4|x|x|x|x|x|x|x|x|x|x|-|-|
|24.0.5|x|x|x|x|x|x|x|x|x|x|-|-|
|25.0.0|x|x|x|x|x|x|x|x|x|x|-|-|
|25.0.1|x|x|x|x|x|x|x|x|x|x|-|-|
|25.0.2|x|x|x|x|x|x|x|x|x|x|-|-|
|25.0.4|x|x|x|x|x|x|x|x|x|x|-|-|
|25.0.5|x|x|x|x|x|x|x|x|x|x|-|-|
|25.0.6|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.0|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.1|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.2|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.4|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.5|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.6|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.7|x|x|x|x|x|x|x|x|x|x|-|-|
|26.0.8|x|x|x|x|x|x|x|x|x|x|-|-|
|26.1.0|x|x|x|x|x|x|x|x|x|x|-|-|
|26.1.1|x|x|x|x|x|x|x|x|x|x|-|-|
|26.1.2|x|x|x|x|x|x|x|x|x|x|-|-|
|26.1.3|x|x|x|x|x|x|x|x|x|x|-|-|
|26.1.4|x|x|x|x|x|x|x|x|x|x|-|-|
|26.1.5|x|x|x|x|x|x|x|x|x|x|-|-|
|26.2.0|x|x|x|x|x|x|-(*7)|x|x|x|-|-|
|26.2.1|x|x|x|x|x|x|-(*7)|x|x|x|-|-|
|26.2.2|x|x|x|x|x|x|-(*7)|x|x|x|-|-|
|26.2.3|x|x|x|x|x|x|x|x|x|x|-|-|
|26.2.4|x|x|x|x|x|x|x|x|x|x|-|-|
|26.2.5|x|x|x|x|x|x|x|x|x|x|-|-|
|26.3.0|x|x|x|x|x|x|x|x|x|x|x(*10)|x(*11)|
|26.3.1|x|x|x|x|x|x|x|x|x|x|x(*10)|x(*11)|
|26.3.2|x|x|x|x|x|x|x|x|x|x|x(*10)|x(*11)|
|26.3.3|x|x|x|x|x|x|x|x|x|x|x(*10)|x(*11)|
|26.3.4|x|x|x|x|x|x|x|x|x|x|x(*10)|x(*11)|
|26.3.5|x|x|x|x|x|x|x|x|x|x|x(*10)|x(*11)|
|26.4.0|x(*12)|x(*12)(*13)|x(*12)|x(*12)|x(*12)|x(*12)|x|x|x(*12)|x(*12)|x(*12)|x(*12)|
|26.4.1|x|x|x|x|x|x|x|x|x|x|x|x|
|26.4.2|x|x|x|x|x|x|x|x|x|x|x|x|
|26.4.4|x|x|x|x|x|x|x|x|x|x|x|x|
|26.4.5|x|x|x|x|x|x|x|x|x|x|x|x|
|26.4.6|x|x|x|x|x|x|x|x|x|x|x|x|
|26.4.7|x|x|x|x|x|x|x|x|x|x|x|x|
|26.5.0|x|x|-|x|x|x|-(\*16)|x|-|-|x|x|
|26.5.1|x|x|-|x|x|x|-(\*16)|x|-|-|x|x|
|26.5.2|x|x|x|x|x|x|x|x|x|x|x|x|
|26.5.3|x|x|x|x|x|x|x|x|x|x|x|x|
|26.5.4|x|x|x|x|x|x|x|x|x|x|x|x|
|26.5.5|x|x|x|x|x|x|x|x|x|x|x|x|
|26.5.6|x|x|x|x|x|x|x|x|x|x|x|x|
|26.5.7|x|x|x|x|x|x|x|x|x|x|x|x|
|26.6.0|x|x|x|x|x|x|x|x|x|x|x|x|
|26.6.1|x|x|x|x|x|x|x|x|x|x|x|x|
|26.6.2|x|x|x|x|x|x|x|x|x|x|x|x|

Note: Keycloak legacy (wildfly) is no longer supported since [keycloak 20](https://www.keycloak.org/docs/latest/release_notes/index.html#wildfly-distribution-removed).

\*1 : Up to Implementer's Draft version 2, Open Banking Brazil Security Profile. From Implementer's Draft version 3, Open Finance Brazil Security Profile. Its conformance test is no longer supported since conformance suite version 5.1.11. Therefore, its conformance test is conducted by the conformance suite version 5.1.10.

\*2 : Its conformance test is supported by conformance suite version 5.1.11.

\*3 : Except for Dynamic Client Registration (DCR) conformance profile.

\*4 : Except for 3rd Party-Init OP conformance profile.

\*5 : [ISSUE-25022](https://github.com/keycloak/keycloak/issues/25022)

\*6 : Since keycloak 26.1.0, the FAPI2 with DPoP conformance tests are also passed (FAPI2SP MTLS + DPOP, FAPI2SP private key + DPOP).

\*7 : [ISSUE-39037](https://github.com/keycloak/keycloak/issues/39037)

\*8 : According to [Australia CDR security profile specification](https://consumerdatastandardsaustralia.github.io/standards/#authentication-flows), From May 12th 2025, JARM is mandatory, and it seems that the conformance suite from v5.1.33 only accepts the "AU-CDR Adv. OP w/ Private Key, PAR, JARM" conformance profile while the current Conformance Test Execution Platform can run the "AU-CDR Adv. OP w/ Private Key" and "AU-CDR Adv. OP w/ Private Key, PAR" conformance profile tests. Therfore, from the conformance suite version v5.1.33, it only tests "AU-CDR Adv. OP w/ Private Key, PAR, JARM" conformance profile.

\*9 : Since conformance suite version 5.1.33, FAPI 2.0 Security Profile Final and Message Signing Final conformance test is supported.

\*10 : Due to [ISSUE-41119](https://github.com/keycloak/keycloak/issues/41119), Keycloak can pass some conformance tests among the five conformance profiles' conformance tests of FAPI 2.0 Serurity Profile Final specification:
 - FAPI2SP MTLS + MTLS: passed
 - FAPI2SP MTLS + DPOP: passed
 - FAPI2SP private key + MTLS: not passed
 - FAPI2SP private key + DPOP: not passed
 - FAPI2SP OpenID Connect: passed (if not using private_key_jwt as client authentication method)

\*11 : Due to [ISSUE-41119](https://github.com/keycloak/keycloak/issues/41119), , Keycloak can pass some conformance tests among the two conformance profiles' conformance tests of FAPI 2.0 Message Signing Final specification:
 - FAPI2MS JAR: passed (if not using private_key_jwt as client authentication method)
 - FAPI2MS JARM: passed (if not using private_key_jwt as client authentication method)

\*12 : Due to [ISSUE-43269](https://github.com/keycloak/keycloak/issues/43269), Keycloak cannot pass the following conformance tests:
 - FAPI 1.0 Advanced Final (w/ private_key_jwt as client authentication method)
 - FAPI 2.0 Security Profile Final (w/ private_key_jwt as client authentication method)
 - FAPI 2.0 Message Signing Final (w/ private_key_jwt as client authentication method)
 - FAPI 2.0 Security Profile Implementer’s Draft version 2 (w/ private_key_jwt as client authentication method)
 - FAPI 2.0 Message Signing Implementer’s Draft version 1 (w/ private_key_jwt as client authentication method)
 - FAPI-CIBA (w/ private_key_jwt as client authentication method)
 - UK Open Banking (w/ private_key_jwt as client authentication method)
 - Australia Consumer Data Right (w/ private_key_jwt as client authentication method)
 - Open Finance Brazil (w/ private_key_jwt as client authentication method)

 while Keycloak still can pass the following conformance tests:
 - FAPI 1.0 Advanced Final (w/ mtls as client authentication method)
 - FAPI 2.0 Security Profile Final (w/ mtls as client authentication method)
 - FAPI 2.0 Message Signing Final (w/ mtls as client authentication method)
 - FAPI 2.0 Security Profile Implementer’s Draft version 2 (w/ mtls as client authentication method)
 - FAPI 2.0 Message Signing Implementer’s Draft version 1 (w/ mtls as client authentication method)
 - FAPI-CIBA (w/ mtls as client authentication method)
 - UK Open Banking (w/ mtls as client authentication method)
 - Open Finance Brazil (w/ mtls as client authentication method)

\*13 : Due to [ISSUE-43270](https://github.com/keycloak/keycloak/issues/43270), Keycloak cannot pass the following conformance tests:
 - FAPI-CIBA (w/ private_key_jwt as client authentication method)

 while Keycloak still can pass the following conformance tests:
 - FAPI-CIBA (w/ mtls as client authentication method)

\*14 : FAPI 2.0 final version was released. Therefore, FAPI 2.0 draft version conformance is no longer checked.

\*15 : Open Finance Brasil, the successor of Open Banking Brasil was relased. Therefore, Open Banking Brasil is no longer checked.

\*16 : [ISSUE-45250](https://github.com/keycloak/keycloak/issues/45250)

## Other Contributions

### Hosting Conferences

#### Keyconf 26 (Holiday Inn Prague, Prague, Czech Republic, October 8, 2026)
- URL: https://keyconf.dev

#### Keyconf 25 (Van der Valk Hotel Amsterdam Zuidas – RAI, Amsterdam, Netherlands, August 28, 2025)
- URL: https://keyconf.dev/2025/

#### Keyconf 24 (ARCOTEL Kaiserwasser Wien, Vienna, Austria, September 19, 2024)
- URL: https://keyconf.dev/2024/

#### Keyconf 23 (Level39, London, United Kingdom, June 16, 2023)
- URL: https://www.eventbrite.co.uk/e/keyconf-23-tickets-621079815447

### Conference Speech

#### Keyconf 25 (Van der Valk Hotel Amsterdam Zuidas – RAI, Amsterdam, Netherlands, August 28, 2025)
- Title: Keycloak & OpenID Federation: Empowering Dynamic Trust in Federated Environments
- Title: Keycloak meets AI: the possibility of integrating Keycloak with AI
- URL: https://keyconf.dev/

#### Open Source Summit Europe 2025 (RAI Amsterdam Convention Centre, Amsterdam, Netherlands, August 25, 2025)
- Title: Confirming Safety of IAM Specifications and Their OSS Implementations: Keycloak as a Case Study
- URL: https://osseu2025.sched.com/event/25VoP/confirming-safety-of-iam-specifications-and-their-oss-implementations-keycloak-as-a-case-study-takashi-norimatsu-hitachi-ltd

#### KubeCon + CloudNativeCon Japan 2025 (Hilton Tokyo Odaiba Hotel, Tokyo, Japan, June 16, 2025)
- Title: Add Single-sign-on To Your Applications With Keycloak and Learn About Its Latest Features
- URL: https://kccncjpn2025.sched.com/event/1x6zG/add-single-sign-on-to-your-applications-with-keycloak-and-learn-about-its-latest-features-takashi-norimatsu-hitachi-marek-posolda-red-hat

#### KeycloakCon Japan 2025 (Hilton Tokyo Odaiba Hotel, Tokyo, Japan, June 13, 2025)
- Title: Keycloak Introduction and Demo
- URL: https://keycloakconjapan2025.sched.com/event/2346Y/keynote-keycloak-introduction-and-demo-marek-posolda-keycloak-project-maintainer
- Title: AI Agents with Keycloak in MCP
- URL: https://keycloakconjapan2025.sched.com/event/23EFm/keynote-ai-agents-with-keycloak-in-mcp-takashi-norimatsu-senior-oss-specialist-hitachi-ltd

#### KubeCon + CloudNativeCon Europe 2025 (Excel London, London, United Kingdom, April 4, 2025)
- Title: Evolving OpenID Connect and Observability in Keycloak
- URL: https://kccnceu2025.sched.com/event/1td1c/evolving-openid-connect-and-observability-in-keycloak-ryan-emerson-red-hat-takashi-norimatsu-hitachi

#### Keycloak DevDay 2025 (greet Hotel Darmstadt, Germany, Darmstadt, March 6, 2025)
- Title: Enhancing Group Management in Keycloak: A Flexible Extension for Dynamic Membership Control
- Title: Keycloak's Compliance with Security Specifications : from OAuth 2.0, OIDC to OID4VCI
- Title: Mastering Access Control: Low-Code Authorization with ReBAC, Decoupling Patterns and Policy as Code
- Title: Strengthening Security in Keycloak: An Introduction to the Shared Signals Framework
- URL: https://www.keycloak-day.dev/

#### OAuth Security Workshop 2025 (Harpa Concert Hall and Conference Centre, Iceland, Reykjavík, February 27, 2025)
- Title: How to confirm an OAuth2/OIDC product is secure - a conformance test and vulnerability test
- URL: https://talks.secworkshop.events/osw2025/talk/HBZMVK/

#### FOSDEM 2025 (Université Libre de Bruxelles Campus du Solbosch, Belgium, Brussels, February 1, 2025)
- Title: Using DPoP to use access tokens securely in your Single Page Applications
- URL: https://fosdem.org/2025/schedule/event/fosdem-2025-5370-using-dpop-to-use-access-tokens-securely-in-your-single-page-applications/

#### Keyconf 24 (ARCOTEL Kaiserwasser Wien, Vienna, Austria, September 19, 2024)
- Title: The Journey, Achievements, and Significance of the Keycloak SIG Community
- Title: Streamlining Keycloak Configuration Management: Exploring keycloak-config-cli
- Title: Keycloak's Updates on Emerging Paradigm of Identity and Compliance with Security Specifications
- Title: Core Keycloak features developed in past 12 months
- Title: Integrating Keycloak with Openresty as a resource server in Open Banking
- Title: New and Noteworthy in the OAuth World
- URL: https://keyconf.dev/2024/

#### Open Source Summit Europe 2024 (Austria Centre Vienna, Vienna, Austria, September 18, 2024)
- Title: Securing Workloads with Transaction Tokens and Minicloak 
- URL: https://osseu2024.sched.com/event/1ej7U/securing-workloads-with-transaction-tokens-and-minicloak-dmitry-telegin-backbase

#### OAuth Security Workshop 2024 (Auditorium Antonianum, Rome, Italy, April 11, 2024)
- Title: Supporting OAuth 2.0 Based Security Profiles to Open-source Software - from Implementation to Operation
- URL: https://oauth.secworkshop.events/osw2024/agenda-thursday-osw-2024

#### KubeCon + CloudNativeCon Europe 2024 (Paris Expo Porte de Versailles, Paris, France, March 22, 2024)
- Title: The Leading Edge of AuthN and AuthZ by Keycloak
- URL: https://kccnceu2024.sched.com/event/1YhiQ/the-leading-edge-of-authn-and-authz-by-keycloak-takashi-norimatsu-hitachi-thomas-darimont-codecentric-ag

#### OpenID Summit Tokyo 2024 (Shibuya Stream Hall, Tokyo, Japan, January 19, 2024)
- Title: Implementing OAuth 2.0-based Security Profiles on Open-source Software
- URL: https://www.openid.or.jp/summit/2024/en/

#### KubeCon + CloudNativeCon North America 2023 (McCormick Place West, Chicago, Illinois, United States of America, November 7, 2023)
- Title: 10 Years of Keycloak - What's Next for Cloud-Native Authentication and OIDC?
- URL: https://kccncna2023.sched.com/event/1R2mH/10-years-of-keycloak-whats-next-for-cloud-native-authentication-and-oidc-alexander-schwartz-red-hat-takashi-norimatsu-hitachi-ltd

#### Keyconf 23 (Level39, London, United Kingdom, June 16, 2023)
- Title: Recently added features in Keycloak in past years that make Keycloak a strong performer in the IAM marke
- Title: OpenID FAPI work in the last 12 months
- Title: Keycloak in Open Banking or consent-driven open data ecosystem
- Title: OpenID FAPI presentation
- Title: Roadmap on possible ideas for the future work of Keycloak
- URL: https://www.eventbrite.co.uk/e/keyconf-23-tickets-621079815447

#### Apidays Paris 2022 (Cité des sciences et de l'industrie, Paris, France, December 6, 2022)
- Title: Securing APIs in Open Banking - Financial-grade API security profile implementation to open-source software
- URL: https://speakerdeck.com/apidays/apidays-paris-2022-securing-apis-in-open-banking-takashi-norimatsu-hitachi

#### OAuth Security Workshop 2021 (Virtual Event, December 1, 2021)
- Title: Consideration on how to apply multiple FAPI and its related security profiles dynamically
- URL: https://www.youtube.com/watch?app=desktop&v=_ei7e8aOfkY

### PhD Dissertation
- Title: A Study on Information Security for End-to-End Communication by TCP/IP Internet Protocol Suite
- DOI: http://doi.org/10.18926/68835

### Referred academic paper

#### Developing the Flexible Conformance Test Execution Platform for OAuth 2.0-based Security Profiles
- Journal: Journal of Information Processing, Volume 33, pp.168-183, Information Processing Society of Japan, February 15, 2025.
- DOI: https://doi.org/10.2197/ipsjjip.33.168
- URL: https://www.jstage.jst.go.jp/article/ipsjjip/33/0/33_168/_pdf

#### Policy-Based Method for Applying OAuth 2.0-Based Security Profiles
- Journal: IEICE Transactions on Information and Systems, Volume E106.D-9, pp.1364-1379, Institute of Electronics, Information and Communications Engineers (IEICE), Septempber 1, 2023.
- DOI: https://doi.org/10.1587/transinf.2022icp0004 
- URL: https://www.jstage.jst.go.jp/article/transinf/E106.D/9/E106.D_2022ICP0004/_pdf

### Oral presentation of refereed international conference paper

#### Flexible Method for Supporting OAuth 2.0 Based Security Profiles in Keycloak
- Proceedings: Lecture Notes in Informatics (LNI) Proceedings of Open Identity Summit 2022, P-325, pp.87-98, DTU Compute, Lyngby, Denmark, July 7-8, 2022.
- DOI: https://doi.org/10.18420/OID2022_07
- DBLP: https://dblp.uni-trier.de/rec/conf/openidentity/NorimatsuNY22
- URL: https://dblp.uni-trier.de/rec/conf/openidentity/2022
- URL: https://dblp.uni-trier.de/db/conf/openidentity/openidentity2022.html#NorimatsuNY22

## Communication Channels

Not only OAuth SIG member but others can communicate with each other by the following ways.

- Slack : Cloud Native Computing Foundation (CNCF) slack's channel #keycloak-oauth-sig
- Mail : Google Group [keycloak developer mailing list](https://groups.google.com/forum/#!topic/keycloak-dev/Ck_1i5LHFrE)
- Chat : Zulip Chat stream ([#dev-sig-fapi](https://keycloak.zulipchat.com/#narrow/stream/248413-dev-sig-fapi))
- Meeting : Web meeting on a regular basis
  - When: https://zoom-lfx.platform.linuxfoundation.org/meetings/keycloak?view=week
  - Where: https://zoom-lfx.platform.linuxfoundation.org/meeting/96822989424?password=b61bd841-bb84-48e3-a88b-f1750d41d801
  - Agenda and minute: https://hackmd.io/@keycloak-oauth-sig

## Automated Conformance Test Run Environment

Please see [conformance-tests-env](./conformance-tests-env/README.md).

## License

* [Apache License, Version 2.0](./LICENSE)

