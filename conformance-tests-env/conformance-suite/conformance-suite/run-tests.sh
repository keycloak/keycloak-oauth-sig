#!/bin/bash

set -e
cleanup() {
    echo
    echo
    echo "`date '+%Y-%m-%d %H:%M:%S'`: run-tests.sh exiting"
    echo
    echo
}
trap cleanup EXIT

echo
echo
echo "`date '+%Y-%m-%d %H:%M:%S'`: run-tests.sh starting"
echo
echo

# to run tests against a cloud environment, you need to:
# 1. create an API token
# 2. set the CONFORMANCE_TOKEN environment variable to the token
# 3. do "source demo-environ.sh" (or whichever environment you want to run against)
# (to run against your local deployment, just don't do the 'source' command)

TESTS=""
EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-server.json|../conformance-suite/.gitlab-ci/expected-failures-ciba.json|../conformance-suite/.gitlab-ci/expected-failures-client.json"
EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-server.json|../conformance-suite/.gitlab-ci/expected-skips-ciba.json|../conformance-suite/.gitlab-ci/expected-skips-client.json"

makeClientTest() {
    . ./node-client-setup.sh
    . ./node-core-client-setup.sh
    . ./ksa-client-setup.sh

    #BRAZIL (note brazil_client_scope is not a variant but is used to pass scopes to tests. brazil_client_scope values use - instead of space)
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_client_type=oidc][brazil_client_scope=openid-payments] automated-brazil-client-test-payments.json"
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_client_type=oidc][brazil_client_scope=openid-accounts] automated-brazil-client-test.json"

    # client FAPI1-ADVANCED
    #TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_auth_request_method=pushed][fapi_response_mode=jarm][fapi_client_type=plain_oauth] automated-brazil-client-test-no-openid-scope.json"
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_auth_request_method=by_value][fapi_response_mode=plain_response][fapi_client_type=oidc] automated-ob-client-test.json"
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_auth_request_method=pushed][fapi_response_mode=jarm][fapi_client_type=oidc] automated-ob-client-test.json"
    #TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_client_type=oidc] automated-ob-client-test.json"
    #TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_auth_request_method=by_value][fapi_response_mode=jarm][fapi_client_type=oidc] automated-ob-client-test.json"
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_auth_request_method=by_value][fapi_response_mode=jarm][fapi_client_type=plain_oauth] automated-ob-client-test-no-openid-scope.json"


    # client FAPI-RW-ID2
    TESTS="${TESTS} fapi-rw-id2-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_auth_request_method=by_value][fapi_response_mode=plain_response][fapi_client_type=oidc] automated-ob-client-test.json"
    TESTS="${TESTS} fapi-rw-id2-client-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_auth_request_method=by_value][fapi_response_mode=plain_response][fapi_client_type=oidc] automated-ob-client-test.json"

    # client FAPI-RW-ID2-OB
    TESTS="${TESTS} fapi-rw-id2-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_uk][fapi_auth_request_method=by_value][fapi_response_mode=plain_response][fapi_client_type=oidc] automated-ob-client-test.json"
    TESTS="${TESTS} fapi-rw-id2-client-test-plan[client_auth_type=mtls][fapi_profile=openbanking_uk][fapi_auth_request_method=by_value][fapi_response_mode=plain_response][fapi_client_type=oidc] automated-ob-client-test.json"

    # client OpenID Connect Core Client Tests
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[id_token_encrypted_response_alg=A128KW][userinfo_encrypted_response_alg=A128GCMKW][request_object_encryption_alg=RSA-OAEP]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=code\ token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[userinfo_encrypted_response_alg=ECDH-ES][userinfo_signed_response_alg=ES256]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token\ token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[id_token_signed_response_alg=PS256]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=id_token\ token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[id_token_signed_response_alg=ES256]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_post][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[id_token_signed_response_alg=ES256K][userinfo_signed_response_alg=EdDSA]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_post][response_type=code id_token token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[id_token_encrypted_response_alg=RSA-OAEP][id_token_encrypted_response_enc=A192CBC-HS384][userinfo_encrypted_response_alg=ECDH-ES][userinfo_encrypted_response_enc=A128CBC-HS256]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_jwt][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[userinfo_encrypted_response_alg=ECDH-ES][userinfo_encrypted_response_enc=A192CBC-HS384]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token\ token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"

    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=private_key_jwt][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[token_endpoint_auth_signing_alg=ES256]}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token\ token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[token_endpoint_auth_signing_alg=ES256]}_ automated-oidcc-client-test.json"

    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=none][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=none][response_type=code\ id_token\ token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=none][response_type=id_token\ token][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"

    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=code][response_mode=form_post][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=code id_token token][response_mode=form_post][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"

    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=code][response_mode=default][request_type=request_object][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token\ token][response_mode=default][request_type=request_object][client_registration=dynamic_client]{sample-openid-client-nodejs[request_object_encryption_alg=ECDH-ES]}_ automated-oidcc-client-test.json"

    TESTS="${TESTS}  oidcc-client-test-plan[client_auth_type=tls_client_auth][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs[tls_client_auth_subject_dn=cn=test.certification.example.com,o=oidf,l=san ramon,st=ca,c=us](CLIENT_CERT=../../conformance-suite/.gitlab-ci/rp_tests-tls_client_auth.crt)(CLIENT_CERT_KEY=../../conformance-suite/.gitlab-ci/rp_tests-tls_client_auth.key)}_ automated-oidcc-client-test.json"
    TESTS="${TESTS} oidcc-client-test-plan[client_auth_type=self_signed_tls_client_auth][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs(CLIENT_CERT=../../conformance-suite/.gitlab-ci/rp_tests-tls_client_auth.crt)(CLIENT_CERT_KEY=../../conformance-suite/.gitlab-ci/rp_tests-tls_client_auth.key)}_ automated-oidcc-client-test.json"


    # OIDC Core RP refresh token tests
    TESTS="${TESTS} oidcc-client-refreshtoken-test-plan[client_auth_type=client_secret_basic][response_type=code][response_mode=default][request_type=plain_http_request][client_registration=dynamic_client]{sample-openid-client-nodejs}_ automated-oidcc-client-test.json"


    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=mtls][fapi_profile=openbanking_ksa][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_client_type=oidc] ./ksa-rp-client/fapi-ksa-rp-test-config-mtls.json"
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_ksa][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_client_type=oidc] ./ksa-rp-client/fapi-ksa-rp-test-config-mtls.json"
}

makeServerTest() {

    # FAPI2 security profile
    # plain oauth
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[openid=plain_oauth][client_auth_type=mtls][sender_constrain=mtls][fapi_profile=plain_fapi] authlete-fapi2securityprofile-mtls-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-id2-test-plan[openid=plain_oauth][client_auth_type=private_key_jwt][sender_constrain=mtls][fapi_profile=plain_fapi] authlete-fapi2securityprofile-privatekey-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[openid=plain_oauth][client_auth_type=mtls][sender_constrain=mtls][fapi_profile=plain_fapi] authlete-fapi2securityprofile-mtls-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[openid=plain_oauth][client_auth_type=private_key_jwt][sender_constrain=mtls][fapi_profile=plain_fapi] authlete-fapi2securityprofile-privatekey-plainoauth.json"

    # oidc
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][sender_constrain=mtls][fapi_profile=plain_fapi] authlete-fapi2securityprofile-privatekey.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][sender_constrain=mtls][fapi_profile=plain_fapi] authlete-fapi2securityprofile-privatekey.json"

    # FAPI2 message signing - jar
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response] authlete-fapi2securityprofile-privatekey-jar.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response] authlete-fapi2securityprofile-privatekey-jar.json"

    # FAPI2 message signing - jarm
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=mtls][fapi_response_mode=jarm][fapi_profile=plain_fapi] authlete-fapi2securityprofile-privatekey-jarm.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=mtls][fapi_response_mode=jarm][fapi_profile=plain_fapi] authlete-fapi2securityprofile-privatekey-jarm.json"

    # Brazil
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][sender_constrain=dpop][fapi_profile=openbanking_brazil] authlete-fapi2securityprofile-brazil-privatekey-dpop.json"
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[openid=plain_oauth][client_auth_type=private_key_jwt][sender_constrain=mtls][fapi_profile=openbanking_brazil] authlete-fapi2securityprofile-brazil-privatekey-plainoauth.json"
    TESTS="${TESTS} fapi2-security-profile-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][sender_constrain=dpop][fapi_profile=openbanking_brazil] authlete-fapi2securityprofile-brazil-privatekey-dpop.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[openid=plain_oauth][client_auth_type=private_key_jwt][sender_constrain=mtls][fapi_profile=openbanking_brazil] authlete-fapi2securityprofile-brazil-privatekey-plainoauth.json"

    # FAPI2 message signing - jar + connectid
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response] authlete-fapi2securityprofile-connectid-privatekey.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response] authlete-fapi2securityprofile-connectid-privatekey.json"

    # FAPI2 message signing - jarm
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=mtls][fapi_response_mode=jarm][fapi_profile=openbanking_brazil] authlete-fapi2securityprofile-brazil-privatekey-jarm.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=mtls][fapi_response_mode=jarm][fapi_profile=openbanking_brazil] authlete-fapi2securityprofile-brazil-privatekey-jarm.json"

    #FAPI2 CBUAE - jar + rar
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=cbuae][fapi_response_mode=plain_response][authorization_request_type=rar]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=cbuae][fapi_response_mode=plain_response][authorization_request_type=rar]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-par-without-duplicate-parameters}../conformance-suite/scripts/test-configs-rp-against-op/cbuae-op.json ../conformance-suite/scripts/test-configs-rp-against-op/cbuae-rp.json"
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=cbuae][fapi_response_mode=plain_response][authorization_request_type=rar] authlete-fapi2securityprofile-privatekey-jar-cbuae.json"
    #TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=cbuae][fapi_response_mode=plain_response][authorization_request_type=rar]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=cbuae][fapi_response_mode=plain_response][authorization_request_type=rar]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-par-without-duplicate-parameters}../conformance-suite/scripts/test-configs-rp-against-op/cbuae-op.json ../conformance-suite/scripts/test-configs-rp-against-op/cbuae-rp.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=cbuae][fapi_response_mode=plain_response][authorization_request_type=rar] authlete-fapi2securityprofile-privatekey-jar-cbuae.json"

    # OIDCC certification tests - static server, static client configuration
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=static][client_registration=static_client] authlete-oidcc-secret-basic-server-static.json"
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=static][client_registration=static_client] authlete-oidcc-secret-basic-server-static.json"
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=static][client_registration=static_client] authlete-oidcc-secret-basic-server-static.json"
    #TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=static][client_registration=static_client] authlete-oidcc-secret-basic-server-static.json"
    #TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=static][client_registration=static_client] authlete-oidcc-secret-basic-server-static.json"
    TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=static][client_registration=static_client] authlete-oidcc-secret-basic-server-static.json"

    # OIDCC certification tests - server supports discovery, static client
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=discovery][client_registration=static_client] authlete-oidcc-secret-basic.json"
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=discovery][client_registration=static_client] authlete-oidcc-secret-basic.json"
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=discovery][client_registration=static_client] authlete-oidcc-secret-basic.json"
    TESTS="${TESTS} oidcc-config-certification-test-plan authlete-oidcc-secret-basic.json"
    TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=discovery][client_registration=static_client] authlete-oidcc-secret-basic.json"
    #TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=discovery][client_registration=static_client] authlete-oidcc-secret-basic.json"
    #TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=discovery][client_registration=static_client] authlete-oidcc-secret-basic.json"

    # OIDCC certification tests - server supports discovery, using dcr
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    TESTS="${TESTS} oidcc-config-certification-test-plan authlete-oidcc-dcr.json"
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=code\ id_token] authlete-oidcc-dcr.json"
    TESTS="${TESTS} oidcc-3rdparty-init-login-certification-test-plan[response_type=code\ id_token] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] authlete-oidcc-dcr.json"

    # OIDCC
    # commented out tests removed as they don't test something significantly different, in order to keep the test time down
    # client_secret_basic - static client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code][response_mode=default][client_registration=static_client] authlete-oidcc-secret-basic.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-basic.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-basic.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-basic.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=id_token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-basic.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-basic.json"

    # client_secret_basic - dynamic client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"

    # client_secret_post - static client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code][response_mode=default][client_registration=static_client] authlete-oidcc-secret-post.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ id_token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-post.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-post.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-post.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=id_token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-post.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-post.json"

    # client_secret_post - dynamic client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"

    # client_secret_jwt - static client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code][response_mode=default][client_registration=static_client] authlete-oidcc-secret-jwt.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-jwt.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-jwt.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-jwt.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=id_token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-jwt.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-secret-jwt.json"

    # client_secret_jwt - dynamic client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"

    # private_key_jwt - static client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code][response_mode=default][client_registration=static_client] authlete-oidcc-privatekey.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token][response_mode=default][client_registration=static_client] authlete-oidcc-privatekey.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ token][response_mode=default][client_registration=static_client] authlete-oidcc-privatekey.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-privatekey.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=id_token][response_mode=default][client_registration=static_client] authlete-oidcc-privatekey.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=id_token\ token][response_mode=default][client_registration=static_client] authlete-oidcc-privatekey.json"

    # private_key_jwt - dynamic client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=id_token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] authlete-oidcc-dcr.json"

    # form post
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token][response_mode=form_post][client_registration=dynamic_client] authlete-oidcc-dcr.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token\ token][response_mode=form_post][client_registration=dynamic_client] authlete-oidcc-dcr.json"

    # Brazil FAPI Dynamic client registration
    TESTS="${TESTS} fapi1-advanced-final-brazil-dcr-test-plan[fapi_profile=openbanking_brazil][client_auth_type=private_key_jwt][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] authlete-fapi-brazil-dcr.json"

    # Brazil FAPI
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] authlete-fapi-brazil-privatekey-encryptedidtoken.json"

    # authlete openbanking uk
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_uk][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-ob-mtls.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_uk][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-ob-privatekey.json"

    # authlete KSA/SAMA openbanking
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_ksa][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] authlete-fapi1-final-mtls-sama.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_ksa][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] authlete-fapi1-final-privatekey-sama.json"

    # authlete FAPI (request object by value)
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-mtls.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-privatekey.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=consumerdataright_au][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-privatekey-encryptedidtoken.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-mtls-jarm.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-privatekey-jarm.json"

    # authlete FAPI (PAR)
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] authlete-fapi-rw-id2-mtls.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] authlete-fapi-rw-id2-privatekey.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] authlete-fapi-rw-id2-mtls-jarm.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] authlete-fapi1-final-privatekey-jarm-encrypted.json"

    # OP tests run against RP tests
    # MTLS
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=mtls][fapi_client_type=oidc][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi1-advanced-final-client-test{fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    # private_key_jwt
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi1-advanced-final-client-test{fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    # PAR
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_auth_request_method=pushed][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi1-advanced-final-client-test{fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    # JARM
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=mtls][fapi_client_type=oidc][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=jarm]:fapi1-advanced-final-client-test{fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=jarm]:fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    # Brazil OB
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_auth_request_method=pushed][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response]:fapi1-advanced-final-client-test{fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response]:fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-op-test-config-accounts.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-rp-test-config-accounts.json"
    # Brazil OPIN
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_auth_request_method=pushed][fapi_profile=openinsurance_brazil][fapi_response_mode=plain_response]:fapi1-advanced-final-client-test{fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_profile=openinsurance_brazil][fapi_response_mode=plain_response]:fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-op-test-config-opin.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-rp-test-config-opin.json"

    # Brazil OB DCR accounts (private_key_jwt)
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_response_mode=plain_response][fapi_auth_request_method=pushed][fapi_profile=openbanking_brazil]:fapi1-advanced-final-client-brazildcr-happypath-test{fapi1-advanced-final-brazil-dcr-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_profile=openbanking_brazil]:fapi1-advanced-final-brazildcr-happy-flow}../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-op-test-config-accounts-dcr.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-rp-test-config-accounts.json"
    # Brazil OB DCR payments (private_key_jwt)
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_response_mode=plain_response][fapi_auth_request_method=pushed][fapi_profile=openbanking_brazil]:fapi1-advanced-final-client-brazildcr-happypath-test{fapi1-advanced-final-brazil-dcr-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_profile=openbanking_brazil]:fapi1-advanced-final-brazildcr-happy-flow}../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-op-test-config-payments-dcr.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-rp-test-config-payments.json"
    # Brazil OB DCR payments (private_key_jwt). Payment consent request aud as array.
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_response_mode=plain_response][fapi_auth_request_method=pushed][fapi_profile=openbanking_brazil]:fapi1-advanced-final-client-brazildcr-happypath-test{fapi1-advanced-final-brazil-dcr-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_profile=openbanking_brazil]:fapi1-advanced-final-brazildcr-payment-consent-request-aud-as-array}../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-op-test-config-payments-dcr.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-rp-test-config-payments-1.json"
    # Brazil DCR OPIN (private_key_jwt)
    TESTS="${TESTS} fapi1-advanced-final-client-test-plan[client_auth_type=private_key_jwt][fapi_client_type=oidc][fapi_response_mode=plain_response][fapi_auth_request_method=pushed][fapi_profile=openinsurance_brazil]:fapi1-advanced-final-client-brazildcr-happypath-test{fapi1-advanced-final-brazil-dcr-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_response_mode=plain_response][fapi_profile=openinsurance_brazil]:fapi1-advanced-final-brazildcr-happy-flow}../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-op-test-config-opin-dcr.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-brazil-rp-test-config-opin-dcr.json"

    # FAPI2 Advanced OP against RP
      # plain_fapi, signed_non_repudiation, plain_response
         # client_auth=private_key, sender_constrain=mtls
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
         # client_auth=private_key, sender_constrain=dpop
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-no-mtls.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-no-mtls.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"

        # client_auth=mtls, sender_constrain=mtls
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
        # client_auth=mtls, sender_constrain=dpop
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-mtls-client-auth-dpop.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-mtls-client-auth-dpop.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"


    # FAPI2 Advanced OP against RP using EdDSA signing alg
      # plain_fapi, signed_non_repudiation, plain_response
         # client_auth=private_key, sender_constrain=mtls
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"

         # client_auth=private_key, sender_constrain=dpop
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-no-mtls.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
         # client_auth=private_key, sender_constrain=dpop, dpop_signing_alg=es256
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-no-mtls-dpop-es256.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-no-mtls.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-no-mtls-dpop-es256.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config-1.json"

        # client_auth=mtls, sender_constrain=mtls
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
        # client_auth=mtls, sender_constrain=dpop
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-mtls-client-auth-dpop.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
        # client_auth=mtls, sender_constrain=dpop, dpop_signing_alg=es256
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-mtls-client-auth-dpop-es256.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-mtls-client-auth-dpop.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=mtls][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=signed_non_repudiation][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-eddsa-keytest-config-mtls-client-auth-dpop-es256.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-eddsa-keytest-config-1.json"


      # connectid, signed_non_repudiation, plain_response, mtls - connectid discovery+happyflow
    # connectid discovery+happyflow
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-rp-test-config.json"
    # connectid returning identity claims
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-australia-connectid-test-claims-parameter-idtoken-identity-claims}../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-rp-test-config-1.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=connectid_au][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-australia-connectid-test-claims-parameter-idtoken-identity-claims}../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-op-test-config-1.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-au-connectid-rp-test-config-1.json"

    # plain fapi without openid connect
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=plain_oauth][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=plain_oauth][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-no-openid.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config-no-openid.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][fapi_client_type=plain_oauth][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=plain_oauth][client_auth_type=private_key_jwt][fapi_request_method=signed_non_repudiation][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-no-openid.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config-no-openid.json"

      # FAPI2 baseline OP against RP
      # These don't use the baseline test plans as currently the run-test-plan.py syntax for selecting individual models doesn't work for these plans, it ends up specifying extra unnecessary variants when scheduling the test
         # client_auth=private_key, sender_constrain=mtls
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
         # client_auth=private_key, sender_constrain=dpop
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-no-mtls.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
        # client_auth=mtls, sender_constrain=mtls
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=mtls][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=unsigned][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
        # client_auth=mtls, sender_constrain=dpop
    TESTS="${TESTS} fapi2-message-signing-id1-client-test-plan[client_auth_type=mtls][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-client-test-happy-path{fapi2-message-signing-id1-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=unsigned][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-id2-discovery-end-point-verification,fapi2-security-profile-id2-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-mtls-client-auth-dpop.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=private_key_jwt][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=private_key_jwt][fapi_request_method=unsigned][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-no-mtls.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=mtls][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=unsigned][sender_constrain=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"
    TESTS="${TESTS} fapi2-message-signing-final-client-test-plan[client_auth_type=mtls][fapi_request_method=unsigned][fapi_client_type=oidc][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-client-test-happy-path{fapi2-message-signing-final-test-plan[openid=openid_connect][client_auth_type=mtls][fapi_request_method=unsigned][sender_constrain=dpop][fapi_profile=plain_fapi][fapi_response_mode=plain_response]:fapi2-security-profile-final-discovery-end-point-verification,fapi2-security-profile-final-ensure-request-object-with-multiple-aud-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-op-test-config-mtls-client-auth-dpop.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-rp-test-config.json"


    # This is the configuration used in the instructions as an example.
    # We keep it here as we want to be sure code changes don't break the example in the instructions, but the downside is there
    # is a chance that users may be using the alias at the same time our tests are running
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] authlete-fapi-rw-id2-privatekey-for-instructions.json"

    # OpenID4VP op-against-rp
    SDJWT="credential_format=sd_jwt_vc"
    MDL="credential_format=iso_mdl"
    SANDNS="client_id_scheme=x509_san_dns"
    SIGNEDREQ="request_method=request_uri_signed"
    DIRECTPOST="response_mode=direct_post"
    DCQL="query_language=dcql"
    PEX="query_language=presentation_exchange"
    CONFIGS="../conformance-suite/scripts/test-configs-rp-against-op"

    # VP ID2
    TESTS="${TESTS} oid4vp-id2-verifier-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST]:oid4vp-id2-verifier-happy-flow{oid4vp-id2-wallet-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST]:oid4vp-id2-wallet-happy-flow-no-state}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config.json"
    TESTS="${TESTS} oid4vp-id2-verifier-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt]:oid4vp-id2-verifier-happy-flow{oid4vp-id2-wallet-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt]:oid4vp-id2-wallet-happy-flow-with-state-and-redirect}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config-with-redirect.json"
    TESTS="${TESTS} oid4vp-id2-verifier-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt]:oid4vp-id2-verifier-happy-flow{oid4vp-id2-wallet-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt]:oid4vp-id2-wallet-happy-flow-no-state}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config-with-redirect.json"
    TESTS="${TESTS} oid4vp-id2-verifier-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt]:oid4vp-id2-verifier-happy-flow{oid4vp-id2-wallet-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt]:oid4vp-id2-wallet-happy-flow-with-state-and-redirect}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config-with-redirect-alt.json"

    # VP ID3 - DCQL
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST][$DCQL]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST][$DCQL]:oid4vp-id3-wallet-happy-flow-no-state}${CONFIGS}/vp-wallet-test-config-dcql.json ${CONFIGS}/vp-verifier-test-config.json"
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$DCQL]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$DCQL]:oid4vp-id3-wallet-happy-flow-with-state-and-redirect}${CONFIGS}/vp-wallet-test-config-dcql.json ${CONFIGS}/vp-verifier-test-config-with-redirect.json"
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$DCQL]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$DCQL]:oid4vp-id3-wallet-happy-flow-no-state}${CONFIGS}/vp-wallet-test-config-dcql.json ${CONFIGS}/vp-verifier-test-config-with-redirect.json"
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$DCQL]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$DCQL]:oid4vp-id3-wallet-happy-flow-with-state-and-redirect}${CONFIGS}/vp-wallet-test-config-dcql.json ${CONFIGS}/vp-verifier-test-config-with-redirect-alt.json"

    # VP ID3 - Presentation Exchange
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST][$PEX]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST][$PEX]:oid4vp-id3-wallet-happy-flow-no-state}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config.json"
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$PEX]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$SDJWT][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$PEX]:oid4vp-id3-wallet-happy-flow-with-state-and-redirect}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config-with-redirect.json"
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$PEX]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$PEX]:oid4vp-id3-wallet-happy-flow-no-state}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config-with-redirect.json"
    TESTS="${TESTS} oid4vp-id3-verifier-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$PEX]:oid4vp-id3-verifier-happy-flow{oid4vp-id3-wallet-test-plan[$MDL][$SANDNS][$SIGNEDREQ][$DIRECTPOST.jwt][$PEX]:oid4vp-id3-wallet-happy-flow-with-state-and-redirect}${CONFIGS}/vp-wallet-test-config.json ${CONFIGS}/vp-verifier-test-config-with-redirect-alt.json"
}

makeCIBATest() {
    # ciba
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] authlete-fapi-ciba-id1-mtls-poll.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] authlete-fapi-ciba-id1-privatekey-poll.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_profile=openbanking_uk][ciba_mode=poll][client_registration=static_client] authlete-fapi-ciba-id1-mtls-poll.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_uk][ciba_mode=poll][client_registration=static_client] authlete-fapi-ciba-id1-privatekey-poll.json"

    # ciba poll DCR
    #TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][ciba_mode=poll][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][ciba_mode=poll][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_profile=openbanking_uk][ciba_mode=poll][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"
    #TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_uk][ciba_mode=poll][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"

    # ciba ping DCR
    # only one backchannel notification endpoint is allowed in CIBA so DCR must be used for ping testing
    # see https://gitlab.com/openid/conformance-suite/issues/389
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][ciba_mode=ping][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"
    #TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][ciba_mode=ping][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"
    #TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_profile=openbanking_uk][ciba_mode=ping][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_uk][ciba_mode=ping][client_registration=dynamic_client] authlete-fapi-ciba-id1-dcr.json"
    # push isn't allowed in FAPI-CIBA profile
    #TESTS="${TESTS} fapi-ciba-id1-push-with-mtls-test-plan authlete-fapi-ciba-id1-mtls-push.json"

    # FAPI CIBA OP against RP
    # MTLS
    TESTS="${TESTS} fapi-ciba-id1-client-test-plan[client_auth_type=mtls][ciba_mode=poll][fapi_profile=plain_fapi]:fapi-ciba-id1-client-test{fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][ciba_mode=poll][client_registration=static_client]:fapi-ciba-id1-discovery-end-point-verification,fapi-ciba-id1-ensure-other-scope-order-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-rp-test-config.json"
    # PKJWT
    TESTS="${TESTS} fapi-ciba-id1-client-test-plan[client_auth_type=private_key_jwt][ciba_mode=poll][fapi_profile=plain_fapi]:fapi-ciba-id1-client-test{fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][ciba_mode=poll][client_registration=static_client]:fapi-ciba-id1-discovery-end-point-verification,fapi-ciba-id1-ensure-other-scope-order-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-rp-test-config.json"
    # OFBR PKJWT
    TESTS="${TESTS} fapi-ciba-id1-client-test-plan[client_auth_type=private_key_jwt][ciba_mode=poll][fapi_profile=openbanking_brazil]:fapi-ciba-id1-client-test{fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][ciba_mode=poll][client_registration=static_client]:fapi-ciba-id1-brazil-discovery-end-point-verification,fapi-ciba-id1-ensure-other-scope-order-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-rp-test-config.json"
    TESTS="${TESTS} fapi-ciba-id1-client-test-plan[client_auth_type=private_key_jwt][ciba_mode=poll][fapi_profile=openbanking_brazil]:fapi-ciba-id1-client-test{fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][ciba_mode=poll][client_registration=static_client]:fapi-ciba-id1-ensure-other-scope-order-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-op-test-config-login_hint.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-rp-test-config-login_hint.json"
    TESTS="${TESTS} fapi-ciba-id1-client-test-plan[client_auth_type=private_key_jwt][ciba_mode=poll][fapi_profile=openbanking_brazil]:fapi-ciba-id1-client-refresh-token-test{fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][ciba_mode=poll][client_registration=static_client]:fapi-ciba-id1-brazil-discovery-end-point-verification,fapi-ciba-id1-ensure-other-scope-order-succeeds}../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-op-test-config-refresh.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-rp-test-config.json"
    TESTS="${TESTS} fapi-ciba-id1-client-test-plan[client_auth_type=private_key_jwt][ciba_mode=poll][fapi_profile=openbanking_brazil]:fapi-ciba-id1-client-access-denied-test{fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][ciba_mode=poll][client_registration=static_client]:fapi-ciba-id1-brazil-discovery-end-point-verification,fapi-ciba-id1-user-rejects-authentication}../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-rp-test-config.json"
    TESTS="${TESTS} fapi-ciba-id1-client-test-plan[client_auth_type=private_key_jwt][ciba_mode=poll][fapi_profile=openbanking_brazil]:fapi-ciba-id1-client-invalid-request-test{fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][ciba_mode=poll][client_registration=static_client]:fapi-ciba-id1-brazil-discovery-end-point-verification,fapi-ciba-id1-multiple-call-to-token-endpoint}../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-op-test-config.json ../conformance-suite/scripts/test-configs-rp-against-op/fapi-ciba-brazil-rp-test-config.json"
}

makeEkycTests() {
    TESTS="${TESTS} ekyc-test-plan-oidccore[client_auth_type=private_key_jwt][server_metadata=discovery][response_type=code][client_registration=dynamic_client][response_mode=default] authlete-ekyc-privatekey.json"
}

makeFederationTests() {
    TESTS="${TESTS} openid-federation-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/scripts/test-configs-federation/authlete-federation-fapidev-as.json"
    TESTS="${TESTS} openid-federation-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/scripts/test-configs-federation/authlete-federation-trust-anchor.json"
    TESTS="${TESTS} openid-federation-test-plan[server_metadata=static][client_registration=static_client] ../conformance-suite/scripts/test-configs-federation/sweden-federation-bankid.json"
    TESTS="${TESTS} openid-federation-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/scripts/test-configs-federation/sweden-federation-intermediate.json"
    TESTS="${TESTS} openid-federation-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/scripts/test-configs-federation/sweden-federation-trust-anchor.json"
}

makeSsfTests() {
#    TESTS="${TESTS} openid-ssf-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/scripts/test-configs-ssf/xxxx.json"
    echo "SSF not implemented yet"
    TESTS="${TESTS}"
}

makeOid4VciTests() {
#    TESTS="${TESTS} openid-vci-test-plan[server_metadata=discovery] ../conformance-suite/scripts/test-configs-vci/xxxx.json"
    echo "VCI not implemented yet"
    TESTS="${TESTS}"
}

makeLocalProviderTests() {
    # OIDCC certification tests - server supports discovery, using dcr
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-config-certification-test-plan ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=code\ id_token] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-3rdparty-init-login-certification-test-plan[response_type=code\ id_token] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"

    # OIDCC
    # client_secret_basic - dynamic client
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_basic][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"

    # client_secret_post - dynamic client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"

    # client_secret_jwt - dynamic client
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"

    # private_key_jwt - dynamic client
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    #TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=code\ id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=id_token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=private_key_jwt][response_type=id_token\ token][response_mode=default][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"

    # form post
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_post][response_type=code\ id_token][response_mode=form_post][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"
    TESTS="${TESTS} oidcc-test-plan[client_auth_type=client_secret_jwt][response_type=code][response_mode=form_post][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/local-provider-oidcc-conformance-config.json"

}

makePanvaTests() {
    TESTS="${TESTS} fapi-ciba-id1-test-plan[ciba_mode=ping][client_auth_type=mtls][client_registration=dynamic_client][fapi_profile=plain_fapi] panva-fapi-ciba-id1-test-plan.json"
    #TESTS="${TESTS} fapi-ciba-id1-test-plan[ciba_mode=poll][client_auth_type=mtls][client_registration=dynamic_client][fapi_profile=plain_fapi] panva-fapi-ciba-id1-test-plan.json"
    #TESTS="${TESTS} fapi-ciba-id1-test-plan[ciba_mode=ping][client_auth_type=private_key_jwt][client_registration=dynamic_client][fapi_profile=plain_fapi] panva-fapi-ciba-id1-test-plan.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[ciba_mode=poll][client_auth_type=private_key_jwt][client_registration=dynamic_client][fapi_profile=plain_fapi] panva-fapi-ciba-id1-test-plan.json"

    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=jarm] panva-fapi1-advanced-final-test-plan.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=plain_response] panva-fapi1-advanced-final-test-plan.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_auth_request_method=pushed][fapi_profile=plain_fapi][fapi_response_mode=jarm] panva-fapi1-advanced-final-test-plan.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_auth_request_method=pushed][fapi_profile=plain_fapi][fapi_response_mode=plain_response] panva-fapi1-advanced-final-test-plan.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=jarm] panva-fapi1-advanced-final-test-plan-privatejwt.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=by_value][fapi_profile=plain_fapi][fapi_response_mode=plain_response] panva-fapi1-advanced-final-test-plan-privatejwt.json"
    #TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_profile=plain_fapi][fapi_response_mode=jarm] panva-fapi1-advanced-final-test-plan-privatejwt.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_auth_request_method=pushed][fapi_profile=plain_fapi][fapi_response_mode=plain_response] panva-fapi1-advanced-final-test-plan-privatejwt.json"

# FAPI 2 tests temporarily disabled as panva currently supports only FAPI2 final and our FAPI2 final tests aren't quite ready yet
#    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-dpop.json"
    #TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan.json"
    #TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan-plainoauth.json"
    #TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-privatejwt-dpop.json"
    #TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-privatejwt-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan-privatejwt.json"
#    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan-privatejwt-plainoauth.json"
#    TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-dpop.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan-plainoauth.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-privatejwt-dpop.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-message-signing-id1-test-plan-privatejwt-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=openid_connect][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan-privatejwt.json"
#    TESTS="${TESTS} fapi2-message-signing-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_request_method=signed_non_repudiation][fapi_response_mode=jarm][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-message-signing-id1-test-plan-privatejwt-plainoauth.json"

#    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-dpop.json"
    #TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan.json"
    #TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-privatejwt-dpop.json"
    #TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-privatejwt-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan-privatejwt.json"
#    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan-privatejwt-plainoauth.json"
#    TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-dpop.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-privatejwt-dpop.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=dpop] panva-fapi2-security-profile-id2-test-plan-privatejwt-dpop-plainoauth.json"
    #TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=openid_connect][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan-privatejwt.json"
#    TESTS="${TESTS} fapi2-security-profile-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][openid=plain_oauth][sender_constrain=mtls] panva-fapi2-security-profile-id2-test-plan-privatejwt-plainoauth.json"
}

makeFAPI1AdvancedTestCI() {
    # Valiant:
    #   client_auth_type: private_key_jwt
    #   fapi_auth_request_method: by_value
    #   fapi_profile: plain_fapi
    #   fapi_response_mode: plain_response
    # Signature Algorithm: RequestObject:PS256/IDToken:PS256
    # Config File: fapi1-advanced-final-with-private-key-PS256-PS256-automated.json
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value]:fapi1-advanced-final-discovery-end-point-verification,fapi1-advanced-final,fapi1-advanced-final-user-rejects-authentication,fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds,fapi1-advanced-final-ensure-authorization-request-without-state-success,fapi1-advanced-final-ensure-valid-pkce-succeeds,fapi1-advanced-final-ensure-other-scope-order-succeeds,fapi1-advanced-final-access-token-type-header-case-sensitivity,fapi1-advanced-final-ensure-response-mode-query,fapi1-advanced-final-ensure-different-nonce-inside-and-outside-request-object,fapi1-advanced-final-ensure-registered-redirect-uri,fapi1-advanced-final-ensure-request-object-with-long-nonce,fapi1-advanced-final-ensure-request-object-with-64-char-nonce-success,fapi1-advanced-final-ensure-request-object-with-long-state,fapi1-advanced-final-ensure-request-object-without-exp-fails,fapi1-advanced-final-ensure-request-object-without-nbf-fails,fapi1-advanced-final-ensure-request-object-without-scope-fails,fapi1-advanced-final-state-only-outside-request-object-not-used,fapi1-advanced-final-ensure-request-object-without-nonce-fails,fapi1-advanced-final-ensure-request-object-without-redirect-uri-fails,fapi1-advanced-final-ensure-expired-request-object-fails,fapi1-advanced-final-ensure-request-object-with-bad-aud-fails,fapi1-advanced-final-ensure-request-object-with-exp-over-60-fails,fapi1-advanced-final-ensure-request-object-with-nbf-over-60-fails,fapi1-advanced-final-ensure-signed-request-object-with-RS256-fails,fapi1-advanced-final-ensure-request-object-signature-algorithm-is-not-none,fapi1-advanced-final-ensure-request-object-with-invalid-signature-fails,fapi1-advanced-final-ensure-matching-key-in-authorization-request,fapi1-advanced-final-ensure-authorization-request-without-request-object-fails,fapi1-advanced-final-ensure-redirect-uri-in-authorization-request,fapi1-advanced-final-ensure-response-type-code-fails,fapi1-advanced-final-ensure-client-id-in-token-endpoint,fapi1-advanced-final-ensure-mtls-holder-of-key-required,fapi1-advanced-final-ensure-authorization-code-is-bound-to-client,fapi1-advanced-final-attempt-reuse-authorisation-code-after-one-second,fapi1-advanced-final-ensure-signed-client-assertion-with-RS256-fails,fapi1-advanced-final-ensure-client-assertion-in-token-endpoint,fapi1-advanced-final-ensure-client-assertion-with-exp-is-5-minutes-in-past-fails,fapi1-advanced-final-ensure-client-assertion-with-wrong-aud-fails,fapi1-advanced-final-ensure-client-assertion-with-no-sub-fails,fapi1-advanced-final-ensure-client-assertion-with-iss-aud-succeeds,fapi1-advanced-final-refresh-token,fapi1-advanced-final-test-array-as-audience-for-client-JWT-assertion ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-PS256-PS256-automated.json"

    # Valiant:
    #   client_auth_type: private_key_jwt
    #   fapi_auth_request_method: by_value
    #   fapi_profile: plain_fapi
    #   fapi_response_mode: plain_response
    # Signature Algorithm: RequestObject:ES256/IDToken:ES256
    # Config File: fapi1-advanced-final-with-private-key-ES256-ES256-automated.json
    # the following 2 tests are skipped, so not executed explicitly:
    #   fapi1-advanced-final-ensure-signed-request-object-with-RS256-fails
    #   fapi1-advanced-final-ensure-signed-client-assertion-with-RS256-fails
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value]:fapi1-advanced-final-discovery-end-point-verification,fapi1-advanced-final,fapi1-advanced-final-user-rejects-authentication,fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds,fapi1-advanced-final-ensure-authorization-request-without-state-success,fapi1-advanced-final-ensure-valid-pkce-succeeds,fapi1-advanced-final-ensure-other-scope-order-succeeds,fapi1-advanced-final-access-token-type-header-case-sensitivity,fapi1-advanced-final-ensure-response-mode-query,fapi1-advanced-final-ensure-different-nonce-inside-and-outside-request-object,fapi1-advanced-final-ensure-registered-redirect-uri,fapi1-advanced-final-ensure-request-object-with-long-nonce,fapi1-advanced-final-ensure-request-object-with-64-char-nonce-success,fapi1-advanced-final-ensure-request-object-with-long-state,fapi1-advanced-final-ensure-request-object-without-exp-fails,fapi1-advanced-final-ensure-request-object-without-nbf-fails,fapi1-advanced-final-ensure-request-object-without-scope-fails,fapi1-advanced-final-state-only-outside-request-object-not-used,fapi1-advanced-final-ensure-request-object-without-nonce-fails,fapi1-advanced-final-ensure-request-object-without-redirect-uri-fails,fapi1-advanced-final-ensure-expired-request-object-fails,fapi1-advanced-final-ensure-request-object-with-bad-aud-fails,fapi1-advanced-final-ensure-request-object-with-exp-over-60-fails,fapi1-advanced-final-ensure-request-object-with-nbf-over-60-fails,fapi1-advanced-final-ensure-request-object-signature-algorithm-is-not-none,fapi1-advanced-final-ensure-request-object-with-invalid-signature-fails,fapi1-advanced-final-ensure-matching-key-in-authorization-request,fapi1-advanced-final-ensure-authorization-request-without-request-object-fails,fapi1-advanced-final-ensure-redirect-uri-in-authorization-request,fapi1-advanced-final-ensure-response-type-code-fails,fapi1-advanced-final-ensure-client-id-in-token-endpoint,fapi1-advanced-final-ensure-mtls-holder-of-key-required,fapi1-advanced-final-ensure-authorization-code-is-bound-to-client,fapi1-advanced-final-attempt-reuse-authorisation-code-after-one-second,fapi1-advanced-final-ensure-client-assertion-in-token-endpoint,fapi1-advanced-final-ensure-client-assertion-with-exp-is-5-minutes-in-past-fails,fapi1-advanced-final-ensure-client-assertion-with-wrong-aud-fails,fapi1-advanced-final-ensure-client-assertion-with-no-sub-fails,fapi1-advanced-final-ensure-client-assertion-with-iss-aud-succeeds,fapi1-advanced-final-refresh-token,fapi1-advanced-final-test-array-as-audience-for-client-JWT-assertion ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-ES256-ES256-automated.json"

    # Valiant:
    #   client_auth_type: mtls
    #   fapi_auth_request_method: by_value
    #   fapi_profile: plain_fapi
    #   fapi_response_mode: plain_response
    # Signature Algorithm: RequestObject:PS256/IDToken:PS256
    # Config File: fapi1-advanced-final-with-private-key-PS256-PS256-automated.json
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value]:fapi1-advanced-final-discovery-end-point-verification,fapi1-advanced-final,fapi1-advanced-final-user-rejects-authentication,fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds,fapi1-advanced-final-ensure-authorization-request-without-state-success,fapi1-advanced-final-ensure-valid-pkce-succeeds,fapi1-advanced-final-ensure-other-scope-order-succeeds,fapi1-advanced-final-access-token-type-header-case-sensitivity,fapi1-advanced-final-ensure-response-mode-query,fapi1-advanced-final-ensure-different-nonce-inside-and-outside-request-object,fapi1-advanced-final-ensure-registered-redirect-uri,fapi1-advanced-final-ensure-request-object-with-long-nonce,fapi1-advanced-final-ensure-request-object-with-64-char-nonce-success,fapi1-advanced-final-ensure-request-object-with-long-state,fapi1-advanced-final-ensure-request-object-without-exp-fails,fapi1-advanced-final-ensure-request-object-without-nbf-fails,fapi1-advanced-final-ensure-request-object-without-scope-fails,fapi1-advanced-final-state-only-outside-request-object-not-used,fapi1-advanced-final-ensure-request-object-without-nonce-fails,fapi1-advanced-final-ensure-request-object-without-redirect-uri-fails,fapi1-advanced-final-ensure-expired-request-object-fails,fapi1-advanced-final-ensure-request-object-with-bad-aud-fails,fapi1-advanced-final-ensure-request-object-with-exp-over-60-fails,fapi1-advanced-final-ensure-request-object-with-nbf-over-60-fails,fapi1-advanced-final-ensure-signed-request-object-with-RS256-fails,fapi1-advanced-final-ensure-request-object-signature-algorithm-is-not-none,fapi1-advanced-final-ensure-request-object-with-invalid-signature-fails,fapi1-advanced-final-ensure-matching-key-in-authorization-request,fapi1-advanced-final-ensure-authorization-request-without-request-object-fails,fapi1-advanced-final-ensure-redirect-uri-in-authorization-request,fapi1-advanced-final-ensure-response-type-code-fails,fapi1-advanced-final-ensure-client-id-in-token-endpoint,fapi1-advanced-final-ensure-mtls-holder-of-key-required,fapi1-advanced-final-ensure-authorization-code-is-bound-to-client,fapi1-advanced-final-attempt-reuse-authorisation-code-after-one-second,fapi1-advanced-final-refresh-token ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-PS256-PS256-automated.json"

    # Valiant:
    #   client_auth_type: mtls
    #   fapi_auth_request_method: by_value
    #   fapi_profile: plain_fapi
    #   fapi_response_mode: plain_response
    # Signature Algorithm: RequestObject:PS256/IDToken:PS256
    # Config File: fapi1-advanced-final-with-private-key-ES256-ES256-automated.json
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value]:fapi1-advanced-final-discovery-end-point-verification,fapi1-advanced-final,fapi1-advanced-final-user-rejects-authentication,fapi1-advanced-final-ensure-request-object-with-multiple-aud-succeeds,fapi1-advanced-final-ensure-authorization-request-without-state-success,fapi1-advanced-final-ensure-valid-pkce-succeeds,fapi1-advanced-final-ensure-other-scope-order-succeeds,fapi1-advanced-final-access-token-type-header-case-sensitivity,fapi1-advanced-final-ensure-response-mode-query,fapi1-advanced-final-ensure-different-nonce-inside-and-outside-request-object,fapi1-advanced-final-ensure-registered-redirect-uri,fapi1-advanced-final-ensure-request-object-with-long-nonce,fapi1-advanced-final-ensure-request-object-with-64-char-nonce-success,fapi1-advanced-final-ensure-request-object-with-long-state,fapi1-advanced-final-ensure-request-object-without-exp-fails,fapi1-advanced-final-ensure-request-object-without-nbf-fails,fapi1-advanced-final-ensure-request-object-without-scope-fails,fapi1-advanced-final-state-only-outside-request-object-not-used,fapi1-advanced-final-ensure-request-object-without-nonce-fails,fapi1-advanced-final-ensure-request-object-without-redirect-uri-fails,fapi1-advanced-final-ensure-expired-request-object-fails,fapi1-advanced-final-ensure-request-object-with-bad-aud-fails,fapi1-advanced-final-ensure-request-object-with-exp-over-60-fails,fapi1-advanced-final-ensure-request-object-with-nbf-over-60-fails,fapi1-advanced-final-ensure-request-object-signature-algorithm-is-not-none,fapi1-advanced-final-ensure-request-object-with-invalid-signature-fails,fapi1-advanced-final-ensure-matching-key-in-authorization-request,fapi1-advanced-final-ensure-authorization-request-without-request-object-fails,fapi1-advanced-final-ensure-redirect-uri-in-authorization-request,fapi1-advanced-final-ensure-response-type-code-fails,fapi1-advanced-final-ensure-client-id-in-token-endpoint,fapi1-advanced-final-ensure-mtls-holder-of-key-required,fapi1-advanced-final-ensure-authorization-code-is-bound-to-client,fapi1-advanced-final-attempt-reuse-authorisation-code-after-one-second,fapi1-advanced-final-refresh-token ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-ES256-ES256-automated.json"
}

makeFAPI1AdvancedTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-ES256-ES256-automated.json"
}

makeManualFAPI1AdvancedTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-ES256-ES256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-ES256-ES256.json"
}

makeFAPI1AdvancedPARTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-private-key-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-mtls-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-mtls-ES256-ES256-automated.json"
}

makeManualFAPI1AdvancedPARTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-private-key-ES256-ES256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-mtls-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-mtls-ES256-ES256.json"
}

makeFAPI1AdvancedJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-private-key-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-mtls-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-mtls-ES256-ES256-automated.json"
}

makeManualFAPI1AdvancedJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-private-key-ES256-ES256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-mtls-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-jarm-mtls-ES256-ES256.json"
}

makeFAPI1AdvancedPARJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-private-key-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-mtls-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-mtls-ES256-ES256-automated.json"
}

makeManualFAPI1AdvancedPARJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-private-key-ES256-ES256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-mtls-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=plain_fapi][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-par-jarm-mtls-ES256-ES256.json"
}

makeCIBAPollTest() {
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-private-key-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-mtls-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-mtls-ES256-ES256-automated.json"
}

makeManualCIBAPollTest() {
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-private-key-ES256-ES256.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-mtls-PS256-PS256.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=poll][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-poll-mtls-ES256-ES256.json"
}

makeCIBAPingTest() {
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-private-key-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-mtls-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-mtls-ES256-ES256-automated.json"
}

makeManualCIBAPingTest() {
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=private_key_jwt][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-private-key-ES256-ES256.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-mtls-PS256-PS256.json"
    TESTS="${TESTS} fapi-ciba-id1-test-plan[client_auth_type=mtls][fapi_ciba_profile=plain_fapi][ciba_mode=ping][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-ciba/fapi-ciba-id1-ping-mtls-ES256-ES256.json"
}

makeOBBRFAPI1AdvancedTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-final-with-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-final-with-mtls-PS256-PS256-automated.json"   
}

makeManualOBBRFAPI1AdvancedTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-final-with-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-final-with-mtls-PS256-PS256.json"
}

makeOBBRFAPI1AdvancedPARTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-mtls-PS256-PS256-automated.json"   
}

makeManualOBBRFAPI1AdvancedPARTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-mtls-PS256-PS256.json"   
}

makeOBBRFAPI1AdvancedJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-jarm-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-jarm-mtls-PS256-PS256-automated.json" 
}

makeManualOBBRFAPI1AdvancedJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-jarm-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-jarm-mtls-PS256-PS256.json"  
}

makeOBBRFAPI1AdvancedPARJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-jarm-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-jarm-mtls-PS256-PS256-automated.json" 
}

makeManualOBBRFAPI1AdvancedPARJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-jarm-private-key-PS256-PS256.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_brazil][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/ob-br-fapi1-advanced/ob-br-fapi1-advanced-par-jarm-mtls-PS256-PS256.json"  
}

makeOFBRFAPI1AdvancedTest() {
    # for FAPI OP - Brazil Open Finance (FAPI-BR v2)
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_brazil][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/of-br-fapi1-advanced/of-br-fapi1-advanced-par-private-key-PS256-PS256-automated.json"
}

makeCDRFAPI1AdvancedTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=consumerdataright_au][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-aus-cdr/fapi-aus-cdr-private-key-PS256-PS256-automated.json"
}

makeManualCDRFAPI1AdvancedTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=consumerdataright_au][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-aus-cdr/fapi-aus-cdr-private-key-PS256-PS256.json"
}

makeCDRFAPI1AdvancedPARTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=consumerdataright_au][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-aus-cdr/fapi-aus-cdr-private-key-par-PS256-PS256-automated.json"
}

makeManualCDRFAPI1AdvancedPARTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=consumerdataright_au][fapi_response_mode=plain_response][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-aus-cdr/fapi-aus-cdr-private-key-par-PS256-PS256.json"
}

makeCDRFAPI1AdvancedPARJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=consumerdataright_au][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-aus-cdr/fapi-aus-cdr-private-key-par-jarm-PS256-PS256-automated.json"
}

makeManualCDRFAPI1AdvancedPARJARMTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=consumerdataright_au][fapi_response_mode=jarm][fapi_auth_request_method=pushed] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-aus-cdr/fapi-aus-cdr-private-key-par-jarm-PS256-PS256.json"
}

makeUKOBFAPI1AdvancedTest() {
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=private_key_jwt][fapi_profile=openbanking_uk][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-uk-ob/fapi-uk-ob-private-key-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi1-advanced-final-test-plan[client_auth_type=mtls][fapi_profile=openbanking_uk][fapi_response_mode=plain_response][fapi_auth_request_method=by_value] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi-uk-ob/fapi-uk-ob-mtls-PS256-PS256-automated.json"
}

makeManualOIDCConfigTest() {
    TESTS="${TESTS} oidcc-config-certification-test-plan ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-config.json"
}

makeOIDCConfigTest() {
    TESTS="${TESTS} oidcc-config-certification-test-plan ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-config-automated.json"
}

makeManualOIDCBasicTest() {
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-basic.json"
}

makeOIDCBasicTest() {
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-basic-automated.json"
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-basic-discovery-dynamic-automated.json"
    TESTS="${TESTS} oidcc-basic-certification-test-plan[server_metadata=static][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-basic-static-static-automated.json"
}

makeManualOIDCImplicitTest() {
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-implicit.json"
}

makeOIDCImplicitTest() {
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-implicit-automated.json"
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-implicit-discovery-dynamic-automated.json"
    TESTS="${TESTS} oidcc-implicit-certification-test-plan[server_metadata=static][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-implicit-static-static-automated.json"
}

makeManualOIDCHybridTest() {
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-hybrid.json"
}

makeOIDCHybridTest() {
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-hybrid-automated.json"
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-hybrid-discovery-dynamic-automated.json"
    TESTS="${TESTS} oidcc-hybrid-certification-test-plan[server_metadata=static][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-hybrid-static-static-automated.json"
}

makeManualOIDCFormPostBasicTest() {
    TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-basic.json"
}

makeOIDCFormPostBasicTest() {
    TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-basic-automated.json"
    TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-basic-discovery-dynamic-automated.json"
    TESTS="${TESTS} oidcc-formpost-basic-certification-test-plan[server_metadata=static][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-basic-static-static-automated.json"
}

makeManualOIDCFormPostHybridTest() {
    TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-hybrid.json"
}

makeOIDCFormPostHybridTest() {
    TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-hybrid-automated.json"
    TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-hybrid-discovery-dynamic-automated.json"
    TESTS="${TESTS} oidcc-formpost-hybrid-certification-test-plan[server_metadata=static][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-hybrid-static-static-automated.json"
}

makeManualOIDCFormPostImplicitTest() {
    TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-implicit.json"
}

makeOIDCFormPostImplicitTest() {
    TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=discovery][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-implicit-automated.json"
    TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=discovery][client_registration=dynamic_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-implicit-discovery-dynamic-automated.json"
    TESTS="${TESTS} oidcc-formpost-implicit-certification-test-plan[server_metadata=static][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-formpost-implicit-static-static-automated.json"
}

makeManualOIDCDynamicTest() {
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=code\ id_token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-dynamic.json"
}

makeOIDCDynamicTest() {
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=code\ id_token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-dynamic-automated.json"
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=code\ id_token\ token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-dynamic-automated.json"
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=code] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-dynamic-automated.json"
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=id_token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-dynamic-automated.json"
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=id_token\ token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-dynamic-automated.json"
    TESTS="${TESTS} oidcc-dynamic-certification-test-plan[response_type=code\ token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-dynamic-automated.json"
}

makeManualOIDC3rdpartyInitLoginTest() {
    TESTS="${TESTS} oidcc-3rdparty-init-login-certification-test-plan[response_type=code\ id_token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-3rdparty-init-login.json"
}

makeOIDC3rdpartyInitLoginTest() {
    TESTS="${TESTS} oidcc-3rdparty-init-login-certification-test-plan[response_type=code\ id_token] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc/oidcc-3rdparty-init-login-automated.json"
}

makeManualOIDCFrontchannelRpInitiatedLogoutTest() {
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
}

makeOIDCFrontchannelRpInitiatedLogoutTest() {
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout-automated.json"
}

makeManualOIDCFrontchannelRpInitiatedLogoutTest() {
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-frontchannel-rp-initiated-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-frontchannel-rp-initiated-logout.json"
}

makeOIDCBackchannelRpInitiatedLogoutTest() {
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout-automated.json"
}

makeManualOIDCBackchannelRpInitiatedLogoutTest() {
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-backchannel-rp-initiated-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-backchannel-rp-initiated-logout.json"
}

makeOIDCSessionManagementTest() {
    TESTS="${TESTS} oidcc-session-management-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management-automated.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management-automated.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management-automated.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management-automated.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management-automated.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management-automated.json"
}

makeManualOIDCSessionManagementTest() {
    TESTS="${TESTS} oidcc-session-management-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management.json"
    TESTS="${TESTS} oidcc-session-management-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-session-management.json"
}

makeOIDCRpInitiatedLogoutTest() {
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout-automated.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout-automated.json"
}

makeManualOIDCRpInitiatedLogoutTest() {
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code\ id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code\ id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=id_token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=id_token\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout.json"
    TESTS="${TESTS} oidcc-rp-initiated-logout-certification-test-plan[response_type=code\ token][client_registration=static_client] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/oidc-logout/oidcc-rp-initiated-logout.json"
}

makeFAPI2SPTest() {
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-id2/fapi2-ID2-FAPI2SP-DPOP-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[sender_constrain=dpop][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-id2/fapi2-ID2-FAPI2SP-DPOP-private-key-MTLS-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=openid_connect][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-id2/fapi2-ID2-FAPI2SP-OpenID-Connect-DPOP-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-id2/fapi2-ID2-FAPI2SP-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[sender_constrain=mtls][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-id2/fapi2-ID2-FAPI2SP-private-key-MTLS-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-id2-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=openid_connect][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-id2/fapi2-ID2-FAPI2SP-OpenID-Connect-ES256-ES256-automated.json"
}

makeFAPI2MSTest() {
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=plain_response] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-id1/fapi2-ID1-FAPI2MS-DPOP-JAR-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=jarm] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-id1/fapi2-ID1-FAPI2MS-DPOP-JARM-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=plain_response] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-id1/fapi2-ID1-FAPI2MS-JAR-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-id1-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=jarm] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-id1/fapi2-ID1-FAPI2MS-JARM-MTLS-MTLS-ES256-ES256-automated.json"
}

makeFAPI2SPFinalTest() {
    TESTS="${TESTS} fapi2-security-profile-final-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-final/fapi2-final-FAPI2SP-DPOP-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-final-test-plan[sender_constrain=dpop][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-final/fapi2-final-FAPI2SP-DPOP-private-key-MTLS-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-final-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=openid_connect][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-final/fapi2-final-FAPI2SP-OpenID-Connect-DPOP-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-final-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-final/fapi2-final-FAPI2SP-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-final-test-plan[sender_constrain=mtls][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-final/fapi2-final-FAPI2SP-private-key-MTLS-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi2-security-profile-final-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=openid_connect][fapi_profile=plain_fapi] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-sp-final/fapi2-final-FAPI2SP-OpenID-Connect-ES256-ES256-automated.json"
}

makeFAPI2MSFinalTest() {
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=plain_response] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-DPOP-JAR-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=dpop][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=jarm] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-DPOP-JARM-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=plain_response] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-JAR-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=mtls][client_auth_type=mtls][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=jarm] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-JARM-MTLS-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=mtls][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=plain_response] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-JAR-private-key-MTLS-ES256-ES256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=mtls][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=jarm] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-JARM-private-key-MTLS-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=dpop][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=plain_response] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-DPOP-JAR-private-key-MTLS-PS256-PS256-automated.json"
    TESTS="${TESTS} fapi2-message-signing-final-test-plan[sender_constrain=dpop][client_auth_type=private_key_jwt][authorization_request_type=simple][openid=plain_oauth][fapi_request_method=signed_non_repudiation][fapi_profile=plain_fapi][fapi_response_mode=jarm] ../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi2-ms-final/fapi2-final-FAPI2MS-DPOP-JARM-private-key-MTLS-ES256-ES256-automated.json"
}

TESTS="${TESTS} --verbose"
if [ "$#" -eq 0 ]; then
    echo "Run all tests"
    makeServerTest
    makeCIBATest
    makeClientTest
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    # ignore that logout tests are untested (Authlete doesn't support the RP initiated logout specs)
    TESTS="${TESTS} --show-untested-test-modules all-except-logout"
    TESTS="${TESTS} --export-dir ../conformance-suite"
elif [ "$#" -eq 1 ] && [ "$1" = "--client-tests-only" ]; then
    echo "Run client tests"
    makeClientTest
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-client.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-client.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules client"
    TESTS="${TESTS} --export-dir ../conformance-suite"
elif [ "$#" -eq 1 ] && [ "$1" = "--server-tests-only" ]; then
    echo "Run server tests"
    makeServerTest
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-server.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-server.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    # ignore that logout tests are untested (Authlete doesn't support the RP initiated logout specs)
    TESTS="${TESTS} --show-untested-test-modules server-authlete"
    TESTS="${TESTS} --export-dir ../conformance-suite"
    TESTS="${TESTS} --no-parallel-for-no-alias" # the jobs without aliases aren't the slowest queue, so avoid overwhelming server early on
elif [ "$#" -eq 1 ] && [ "$1" = "--ciba-tests-only" ]; then
    echo "Run ciba tests"
    makeCIBATest
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-ciba.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-ciba.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules ciba"
    TESTS="${TESTS} --export-dir ../conformance-suite"
    TESTS="${TESTS} --no-parallel" # the authlete authentication device simulator doesn't seem to support parallel authorizations
elif [ "$#" -eq 1 ] && [ "$1" = "--ekyc-tests" ]; then
    echo "Run eKYC tests"
    makeEkycTests
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-ekyc.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-ekyc.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules ekyc"
    TESTS="${TESTS} --export-dir ../conformance-suite"
elif [ "$#" -eq 1 ] && [ "$1" = "--federation-tests" ]; then
    echo "Run federation tests"
    makeFederationTests
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-federation.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-federation.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules federation"
    TESTS="${TESTS} --export-dir ../conformance-suite"
elif [ "$#" -eq 1 ] && [ "$1" = "--local-provider-tests" ]; then
    echo "Run local provider tests"
    makeLocalProviderTests
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-local.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-local.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules server-oidc-provider"
    TESTS="${TESTS} --export-dir ."
elif [ "$#" -eq 1 ] && [ "$1" = "--ssf-tests" ]; then
    echo "Run ssf tests"
    makeSsfTests
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-ssf.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-ssf.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules ssf"
    TESTS="${TESTS} --export-dir ../conformance-suite"
elif [ "$#" -eq 1 ] && [ "$1" = "--vci-tests" ]; then
    echo "Run oid4vci tests"
    makeOid4VciTests
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-vci.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-vci.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules vci"
    TESTS="${TESTS} --export-dir ../conformance-suite"
elif [ "$#" -eq 1 ] && [ "$1" = "--panva-tests-only" ]; then
    echo "Run panva tests"
    makePanvaTests
    TESTS="${TESTS} --show-untested-test-modules server-panva"
    TESTS="${TESTS} --export-dir ../conformance-suite"
    TESTS="${TESTS} --no-parallel-for-no-alias" # the jobs without aliases aren't the slowest queue, so avoid overwhelming server early on
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi1-advanced-all" ]; then
    echo "Run fapi1-advanced all tests"
    makeFAPI1AdvancedTest
    makeFAPI1AdvancedPARTest
    makeFAPI1AdvancedJARMTest
    makeFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-ciba-all" ]; then
    echo "Run fapi-ciba all tests"
    makeCIBAPollTest
    makeCIBAPingTest
elif [ "$#" -eq 1 ] && [ "$1" = "--ob-br-fapi1-advanced-all" ]; then
    echo "Run ob-br-fapi1-advanced all tests"
    # obsoleted from conformance suite version 5.1.15
    # Open Banking Brasil specifications were replaced with Open Finance Brazil
    makeOBBRFAPI1AdvancedTest
    makeOBBRFAPI1AdvancedPARTest
    makeOBBRFAPI1AdvancedJARMTest
    makeOBBRFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--of-br-fapi1-advanced-all" ]; then
    echo "Run of-br-fapi1-advanced all tests"
    # for FAPI OP - Brazil Open Finance (FAPI-BR v2)
    makeOFBRFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-all" ]; then
    echo "Run oidc all tests"
    makeOIDCConfigTest
    makeOIDCBasicTest
    makeOIDCImplicitTest
    makeOIDCHybridTest
    makeOIDCFormPostBasicTest
    makeOIDCFormPostImplicitTest
    makeOIDCFormPostHybridTest
    makeOIDCDynamicTest
    makeOIDC3rdpartyInitLoginTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-logout-all" ]; then
    echo "Run oidc logout all tests"
    makeOIDCRpInitiatedLogoutTest
#    makeOIDCSessionManagementTest
#    makeOIDCFrontchannelRpInitiatedLogoutTest
    makeOIDCBackchannelRpInitiatedLogoutTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi2-sp-id2-all" ]; then
    echo "Run fapi2-sp-id2 all tests"
    makeFAPI2SPTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi2-ms-id1-all" ]; then
    echo "Run fapi2-ms-id1 all tests"
    makeFAPI2MSTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi2-sp-final-all" ]; then
    echo "Run fapi2-sp-final all tests"
    makeFAPI2SPFinalTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi2-ms-final-all" ]; then
    echo "Run fapi2-ms-final all tests"
    makeFAPI2MSFinalTest
elif [ "$#" -eq 1 ] && [ "$1" = "--client-tests-only" ]; then
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-client.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-client.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
    TESTS="${TESTS} --show-untested-test-modules client"
    echo "Run client tests"
    makeClientTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi1-advanced-all-ci" ]; then
    echo "Run fapi1-advanced all tests"
    makeFAPI1AdvancedTestCI
    #makeFAPI1AdvancedPARTestCI
    #makeFAPI1AdvancedJARMTestCI
    #makeFAPI1AdvancedPARJARMTestCI
    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/expected-failures-fapi1-advanced-all-ci.json"
    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/fapi-conformance-suite-configs/fapi1-advanced/expected-skips-fapi1-advanced-all-ci.json"
    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi1-advanced" ]; then
#    EXPECTED_FAILURES_FILE="../conformance-suite/.gitlab-ci/expected-failures-server.json"
#    EXPECTED_SKIPS_FILE="../conformance-suite/.gitlab-ci/expected-skips-server.json"
#    TESTS="${TESTS} --expected-failures-file ${EXPECTED_FAILURES_FILE}"
#    TESTS="${TESTS} --expected-skips-file ${EXPECTED_SKIPS_FILE}"
#    TESTS="${TESTS} --show-untested-test-modules server"
    echo "Run fapi1-advanced tests"
    makeFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi1-advanced" ]; then
    echo "Run fapi1-advanced tests manually"
    makeManualFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi1-advanced-par" ]; then
    echo "Run fapi1-advanced PAR tests"
    makeFAPI1AdvancedPARTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi1-advanced-par" ]; then
    echo "Run fapi1-advanced PAR tests manually"
    makeManualFAPI1AdvancedPARTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi1-advanced-jarm" ]; then
    echo "Run fapi1-advanced JARM tests"
    makeFAPI1AdvancedJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi1-advanced-jarm" ]; then
    echo "Run fapi1-advanced JARM tests manually"
    makeManualFAPI1AdvancedJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi1-advanced-par-jarm" ]; then
    echo "Run fapi1-advanced PAR JARM tests"
    makeFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi1-advanced-par-jarm" ]; then
    echo "Run fapi1-advanced PAR JARM tests manually"
    makeManualFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-ciba-poll-id1" ]; then
    echo "Run fapi-ciba poll mode tests"
    makeCIBAPollTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi-ciba-poll-id1" ]; then
    echo "Run fapi-ciba poll mode tests manually"
    makeManualCIBAPollTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-ciba-ping-id1" ]; then
    echo "Run fapi-ciba ping mode tests"
    makeCIBAPingTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi-ciba-ping-id1" ]; then
    echo "Run fapi-ciba ping mode tests manually"
    makeManualCIBAPingTest
elif [ "$#" -eq 1 ] && [ "$1" = "--ob-br-fapi1-advanced" ]; then
    echo "Run Open Banking Brasil fapi1-advanced tests"
    makeOBBRFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-ob-br-fapi1-advanced" ]; then
    echo "Run Open Banking Brasil fapi1-advanced tests manually"
    makeManualOBBRFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--ob-br-fapi1-advanced-par" ]; then
    echo "Run Open Banking Brasil fapi1-advanced-par tests"
    makeOBBRFAPI1AdvancedPARTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-ob-br-fapi1-advanced-par" ]; then
    echo "Run Open Banking Brasil fapi1-advanced-par tests manually"
    makeManualOBBRFAPI1AdvancedPARTest
elif [ "$#" -eq 1 ] && [ "$1" = "--ob-br-fapi1-advanced-jarm" ]; then
    echo "Run Open Banking Brasil fapi1-advanced-jarm tests"
    makeOBBRFAPI1AdvancedJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-ob-br-fapi1-advanced-jarm" ]; then
    echo "Run Open Banking Brasil fapi1-advanced-jarm tests manually"
    makeManualOBBRFAPI1AdvancedJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--ob-br-fapi1-advanced-par-jarm" ]; then
    echo "Run Open Banking Brasil fapi1-advanced-par-jarm tests"
    makeOBBRFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-ob-br-fapi1-advanced-par-jarm" ]; then
    echo "Run Open Banking Brasil fapi1-advanced-par-jarm tests manually"
    makeManualOBBRFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-aus-cdr" ]; then
    echo "Run Australia CDR fapi1-advanced tests"
    makeCDRFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi-aus-cdr" ]; then
    echo "Run Australia CDR fapi1-advanced tests manually"
    makeManualCDRFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-aus-cdr-par" ]; then
    echo "Run Australia CDR PAR fapi1-advanced tests"
    makeCDRFAPI1AdvancedPARTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi-aus-cdr-par" ]; then
    echo "Run Australia CDR PAR fapi1-advanced tests manually"
    makeManualCDRFAPI1AdvancedPARTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-aus-cdr-par-jarm" ]; then
    echo "Run Australia CDR PAR JARM fapi1-advanced tests"
    makeCDRFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi-aus-cdr-par-jarm" ]; then
    echo "Run Australia CDR PAR JARM fapi1-advanced tests manually"
    makeManualCDRFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-fapi-aus-cdr-par" ]; then
    echo "Run Australia CDR PAR fapi1-advanced tests manually"
    makeManualCDRFAPI1AdvancedPARTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-aus-cdr-all" ]; then
    echo "Run Australia CDR fapi1-advanced tests"
# https://consumerdatastandardsaustralia.github.io/standards/#authentication-flows
# From May 12th 2025, must support JARM
#    makeCDRFAPI1AdvancedTest
#    makeCDRFAPI1AdvancedPARTest
    makeCDRFAPI1AdvancedPARJARMTest
elif [ "$#" -eq 1 ] && [ "$1" = "--fapi-uk-ob-all" ]; then
    echo "Run UK OpenBanking fapi1-advanced tests"
    makeUKOBFAPI1AdvancedTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-config" ]; then
    echo "Run OpenID Connect Core: Config Certification Profile Authorization server tests"
    makeOIDCConfigTest   
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-config" ]; then
    echo "Run OpenID Connect Core: Config Certification Profile Authorization server tests manually"
    makeManualOIDCConfigTest 
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-basic" ]; then
    echo "Run OpenID Connect Core: Basic Certification Profile Authorization server test"
    makeOIDCBasicTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-basic" ]; then
    echo "Run OpenID Connect Core: Basic Certification Profile Authorization server test manually"
    makeManualOIDCBasicTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-implicit" ]; then
    echo "Run OpenID Connect Core: Implicit Certification Profile Authorization server test"
    makeOIDCImplicitTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-implicit" ]; then
    echo "Run OpenID Connect Core: Implicit Certification Profile Authorization server test manually"
    makeManualOIDCImplicitTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-hybrid" ]; then
    echo "Run OpenID Connect Core: Hybrid Certification Profile Authorization server test"
    makeOIDCHybridTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-hybrid" ]; then
    echo "Run OpenID Connect Core: Hybrid Certification Profile Authorization server test manually"
    makeManualOIDCHybridTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-formpost-basic" ]; then
    echo "Run OpenID Connect Core: Form Post Basic Certification Profile Authorization server test"
    makeOIDCFormPostBasicTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-formpost-basic" ]; then
    echo "Run OpenID Connect Core: Form Post Basic Certification Profile Authorization server test manually"
    makeManualOIDCFormPostBasicTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-formpost-hybrid" ]; then
    echo "Run OpenID Connect Core: Form Post Hybrid Certification Profile Authorization server test"
    makeOIDCFormPostHybridTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-formpost-hybrid" ]; then
    echo "Run OpenID Connect Core: Form Post Hybrid Certification Profile Authorization server test manually"
    makeManualOIDCFormPostHybridTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-formpost-implicit" ]; then
    echo "Run OpenID Connect Core: Form Post Implicit Certification Profile Authorization server test"
    makeOIDCFormPostImplicitTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-formpost-implicit" ]; then
    echo "Run OpenID Connect Core: Form Post Implicit Certification Profile Authorization server test manually"
    makeManualOIDCFormPostImplicitTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oic-formpost" ]; then
    echo "Run OpenID Connect Core: Form Post Certification Profile Authorization server test"
    makeOIDCFormPostBasicTest
    makeOIDCFormPostImplicitTest
    makeOIDCFormPostHybridTest 
elif [ "$#" -eq 1 ] && [ "$1" = "--oidcc-dynamic" ]; then
    echo "Run OpenID Connect Core: Dynamic Certification Profile Authorization server test"
    makeOIDCDynamicTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-dynamic" ]; then
    echo "Run OpenID Connect Core: Dynamic Certification Profile Authorization server test manually"
    makeManualOIDCDynamicTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-3rdparty-init-login" ]; then
    echo "Run OpenID Connect Core: 3rd party initiated Certification Profile Authorization server test"
    makeOIDC3rdpartyInitLoginTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-3rdparty-init-login" ]; then
    echo "Run OpenID Connect Core: 3rd party initiated Certification Profile Authorization server test"
    makeManualOIDC3rdpartyInitLoginTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-frontchanel-rp-initiated-logout" ]; then
    makeOIDCFrontchannelRpInitiatedLogoutTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-frontchanel-rp-initiated-logout" ]; then
    makeManualOIDCFrontchannelRpInitiatedLogoutTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-backchanel-rp-initiated-logout" ]; then
    makeOIDCBackchannelRpInitiatedLogoutTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-backchanel-rp-initiated-logout" ]; then
    makeManualOIDCBackchannelRpInitiatedLogoutTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-session-management" ]; then
    makeOIDCSessionManagementTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-session-management" ]; then
    makeManualOIDCSessionManagementTest
elif [ "$#" -eq 1 ] && [ "$1" = "--oidc-rp-initiated-logout" ]; then
    makeOIDCRpInitiatedLogoutTest
elif [ "$#" -eq 1 ] && [ "$1" = "--manual-oidc-rp-initiated-logout" ]; then
    makeManualOIDCRpInitiatedLogoutTest
else
    echo "Syntax: run-tests.sh [--client-tests-only|--server-tests-only|--ciba-tests-only|--local-provider-tests|--panva-tests-only|--ekyc-tests|--federation-tests|--ssf-tests|--vci-tests|--fapi1-advanced-all|--fapi-ciba-all|--ob-br-fapi1-advanced-all|--fapi-aus-cdr-all|--fapi-uk-ob-all|--oidc-all|--client-tests-only|--fapi1-advanced|--fapi-ciba-poll-id1|--fapi1-advanced-par|--fapi1-advanced-jarm|--fapi1-advanced-par-jarm|--fapi2-sp-id2-all|--fapi2-ms-id1-all|--fapi2-sp-final-all|--fapi2-ms-final-all|--ob-br-fapi1-advanced|--ob-br-fapi1-advanced-par|--ob-br-fapi1-advanced-jarm|--ob-br-fapi1-advanced-par-jarm|--fapi-aus-cdr|--fapi-aus-cdr-par|--oidc-config|--oidc-basic|--oidc-implicit|--oidc-hybrid|--oidc-formpost|--oidc-dynamic|--oidc-3rdparty-init-login]"
    exit 1
fi

echo ${TESTS} | xargs -s 100000 ../conformance-suite/scripts/run-test-plan.py
