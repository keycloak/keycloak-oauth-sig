#!/usr/bin/env python3
#
# Drives Keycloak for the conformance test modules that wait for input which the conformance suite cannot trigger by
# itself. It plays the part of the Keycloak tests' interaction callbacks
# (https://github.com/keycloak/keycloak/tree/main/tests/conformance):
#
#   * OID4VCI issuer tests of the issuer_initiated variant wait for a credential offer. The holder logs in to an
#     application client with the verifiable_credential_offer application initiated action, Keycloak creates the
#     credential offer and the offer is delivered to the test's credential_offer endpoint. This is repeated each
#     time the test waits for a credential offer (e.g. once per client in the multiple clients test).
#   * OID4VP verifier tests wait for an authorization request. A Keycloak login with the OID4VP identity provider is
#     started, and the openid4vp:// authorization request shown on the login page is delivered to the test's wallet
#     authorization endpoint. In the cross device flow the login is then completed by polling the status endpoint
#     as the login page script does.
#
# run-test-plan.py runs this script (WAITING_INTERACTION_COMMAND) when a test module reaches the WAITING state and
# passes the test module in these environment variables:
#
#   MODULE_ID       id of the test module
#   MODULE_NAME     name of the test module
#   MODULE_VARIANT  variant of the test module (JSON)
#   MODULE_INFO     response of the conformance suite to the test module creation (JSON)
#   MODULE_CONFIG   test plan configuration (JSON), its 'interaction' object configures this script
#
# Other test modules are ignored.
#
import base64
import hashlib
import html
import json
import os
import re
import secrets
import sys
import time
import urllib.parse

import httpx

STATUS_POLL_TIMEOUT_SECONDS = 30
STATUS_POLL_INTERVAL_SECONDS = 0.5
CREDENTIAL_OFFER_TIMEOUT_SECONDS = 300


def log(message):
    print("oid4vc-interaction [{}]: {}".format(os.environ.get("MODULE_NAME", ""), message), flush=True)


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def http_client():
    # The test environment uses self-signed certificates for Keycloak and the conformance suite
    return httpx.Client(verify=False, timeout=60, follow_redirects=True, max_redirects=20)


def module_base_url(info, config):
    url = info.get("url") or "{}/test/a/{}".format(os.environ["CONFORMANCE_SERVER"].rstrip("/"), config["alias"])
    return url.rstrip("/")


def find_tag_attribute(page, tag, tag_id, attribute):
    for match in re.finditer(r"<{}\b[^>]*>".format(tag), page, re.IGNORECASE):
        element = match.group(0)
        if re.search(r'\bid="{}"'.format(re.escape(tag_id)), element):
            value = re.search(r'\b{}="([^"]*)"'.format(attribute), element)
            if value:
                return html.unescape(value.group(1))
    return None


def query_parameter(url, name):
    values = urllib.parse.parse_qs(urllib.parse.urlsplit(url).query).get(name)
    if not values or not values[0]:
        raise RuntimeError("{} does not contain {}".format(url, name))
    return values[0]


def realm_url(interaction):
    return "{}/realms/{}".format(interaction["keycloak_url"].rstrip("/"), interaction["realm"])


########################################
# OID4VCI issuer initiated flow
########################################

def create_credential_offer_uri(interaction, credential_configuration_id):
    """Creates a credential offer through the verifiable_credential_offer application initiated action, the way an
    issuer application would. The action config carries no client id, so the offer has no target client and the
    wallet (the conformance suite) redeems it with its own client."""
    action_config = b64url(json.dumps({
        "credentialConfigurationId": credential_configuration_id,
        "preAuthorized": False
    }).encode("utf-8"))
    realm = realm_url(interaction)
    with http_client() as client:
        response = client.get(realm + "/protocol/openid-connect/auth", params={
            "client_id": interaction["credential_offer_client_id"],
            "redirect_uri": realm + "/account/",
            "response_type": "code",
            "scope": "openid",
            "kc_action": "verifiable_credential_offer:" + action_config
        })
        login_action = find_tag_attribute(response.text, "form", "kc-form-login", "action")
        if login_action is None:
            raise RuntimeError("Keycloak did not show the login page: HTTP {} {}".format(
                response.status_code, response.url))
        response = client.post(login_action, data={
            "username": interaction["username"],
            "password": interaction["password"],
            "credentialId": ""
        })
        offer = find_tag_attribute(response.text, "a", "credential-offer-uri-link", "href")
        if offer is None:
            raise RuntimeError("Keycloak did not show a credential offer: HTTP {} {}".format(
                response.status_code, response.url))
        return query_parameter(offer, "credential_offer_uri")


def deliver_credential_offer(info, config):
    interaction = config["interaction"]
    credential_offer_uri = create_credential_offer_uri(interaction, config["vci"]["credential_configuration_id"])
    log("created credential offer " + credential_offer_uri)
    with http_client() as client:
        response = client.get(module_base_url(info, config) + "/credential_offer",
                              params={"credential_offer_uri": credential_offer_uri})
        if response.status_code // 100 != 2:
            raise RuntimeError("Delivering the credential offer failed: HTTP {} {}".format(
                response.status_code, response.text))
    log("delivered credential offer to the conformance suite")


def deliver_credential_offers(module_id, info, config):
    """Delivers a credential offer every time the test module waits for one, as some test modules (e.g. the
    multiple clients test) wait for a credential offer per client, until the test module finishes."""
    api_base = os.environ["CONFORMANCE_SERVER"].rstrip("/") + "/api"
    delivered = 0
    deadline = time.time() + CREDENTIAL_OFFER_TIMEOUT_SECONDS
    with http_client() as client:
        while time.time() < deadline:
            status = client.get("{}/info/{}".format(api_base, module_id)).json().get("status")
            if status in ("FINISHED", "INTERRUPTED"):
                return
            if status == "WAITING":
                logs = client.get("{}/log/{}".format(api_base, module_id)).json()
                waits = sum(1 for entry in logs if entry.get("src") == "VCIWaitForCredentialOffer")
                if waits > delivered:
                    deliver_credential_offer(info, config)
                    delivered += 1
                    continue
            time.sleep(1)
    raise RuntimeError("Test module did not finish within {} seconds".format(CREDENTIAL_OFFER_TIMEOUT_SECONDS))


########################################
# OID4VP verifier
########################################

def module_status(client, module_id):
    api_base = os.environ["CONFORMANCE_SERVER"].rstrip("/") + "/api"
    return client.get("{}/info/{}".format(api_base, module_id)).json().get("status")


def deliver_authorization_request(module_id, info, config, variant):
    interaction = config["interaction"]
    response_mode = variant.get("response_mode", "direct_post")
    identity_provider = interaction["identity_providers"][response_mode]
    cross_device = interaction.get("cross_device", False)
    realm = realm_url(interaction)
    code_verifier = b64url(secrets.token_bytes(32))

    with http_client() as client:
        # e.g. a test module skipped by the suite does not wait for an authorization request
        if module_status(client, module_id) in ("FINISHED", "INTERRUPTED"):
            log("test module already finished, no authorization request to deliver")
            return
        response = client.get(realm + "/protocol/openid-connect/auth", params={
            "client_id": interaction["client_id"],
            "response_type": "code",
            "scope": "openid",
            "redirect_uri": interaction["keycloak_url"].rstrip("/") + "/callback",
            "code_challenge": b64url(hashlib.sha256(code_verifier.encode("ascii")).digest()),
            "code_challenge_method": "S256",
            "kc_idp_hint": identity_provider
        })
        if response.status_code != 200:
            raise RuntimeError("Keycloak login page returned HTTP {}: {}".format(response.status_code, response.text))
        if cross_device:
            # the cross device wallet link the login page exposes on the QR code image
            match = re.search(r'data-oid4vp-wallet-url="([^"]+)"', response.text)
            wallet_url = html.unescape(match.group(1)) if match else None
        else:
            match = re.search(r"openid4vp://[^\"'\s<]+", response.text)
            wallet_url = html.unescape(match.group(0)) if match else None
        if wallet_url is None:
            raise RuntimeError("Keycloak login page did not contain the {} device wallet link".format(
                "cross" if cross_device else "same"))
        client_id = query_parameter(wallet_url, "client_id")
        request_uri = query_parameter(wallet_url, "request_uri")
        log("delivering authorization request " + wallet_url)

        try:
            response = client.get(module_base_url(info, config) + "/authorize",
                                  params={"client_id": client_id, "request_uri": request_uri})
        except httpx.TransportError as e:
            # e.g. a test module skipped on receiving the authorization request redirects to its results page
            if module_status(client, module_id) in ("FINISHED", "INTERRUPTED"):
                log("test module finished on receiving the authorization request")
                return
            raise e
        log("wallet responded with HTTP {}".format(response.status_code))

        if cross_device:
            complete_cross_device_login(client, module_id, realm, identity_provider, request_uri)


def complete_cross_device_login(client, module_id, realm, identity_provider, request_uri):
    # The wallet answered the cross device direct_post without a redirect, so the completion is only observable
    # through the status endpoint, like the login page script observes it. The negative tests make Keycloak reject the
    # presentation, so the login never completes: stop polling once the test module has finished.
    state = urllib.parse.urlsplit(request_uri).path.rstrip("/").rsplit("/", 1)[-1]
    status_url = "{}/broker/{}/endpoint/status".format(realm, urllib.parse.quote(identity_provider))
    deadline = time.time() + STATUS_POLL_TIMEOUT_SECONDS
    while True:
        status = client.get(status_url, params={"state": state}).json()
        if status.get("status") == "complete":
            response = client.get(status["redirectUri"])
            log("completed the cross device login: HTTP {} {}".format(response.status_code, response.url))
            return
        if status.get("status") != "pending":
            log("cross device login ended with status {}".format(status))
            return
        if module_status(client, module_id) in ("FINISHED", "INTERRUPTED"):
            log("test module finished without completing the cross device login")
            return
        if time.time() > deadline:
            raise RuntimeError("Cross device presentation did not arrive within {} seconds".format(
                STATUS_POLL_TIMEOUT_SECONDS))
        time.sleep(STATUS_POLL_INTERVAL_SECONDS)


def main():
    name = os.environ.get("MODULE_NAME", "")
    variant = json.loads(os.environ.get("MODULE_VARIANT") or "{}")
    info = json.loads(os.environ.get("MODULE_INFO") or "{}")
    config = json.loads(os.environ.get("MODULE_CONFIG") or "{}")
    if "interaction" not in config:
        return 0
    try:
        if name.startswith("oid4vci-1_0-issuer-") \
                and variant.get("vci_authorization_code_flow_variant") == "issuer_initiated":
            deliver_credential_offers(os.environ["MODULE_ID"], info, config)
        elif name.startswith("oid4vp-1final-verifier-"):
            deliver_authorization_request(os.environ["MODULE_ID"], info, config, variant)
    except Exception as e:
        # the test module then fails or times out, which shows up in the test results
        log("failed: {}".format(e))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
