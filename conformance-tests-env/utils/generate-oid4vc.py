#!/usr/bin/env python3
#
# Generates the files needed to run the OID4VCI, OID4VCI-HAIP and OID4VP conformance tests:
#
#   * key material (PEM files) and the PKCS#12 keystores loaded by Keycloak's java-keystore key provider
#       test-target/keycloak/keycloak/oid4vc/
#   * Keycloak realm files
#       test-target/keycloak/keycloak/realms/realm-oid4vci.json
#       test-target/keycloak/keycloak/realms/realm-oid4vci-haip.json
#       test-target/keycloak/keycloak/realms/realm-oid4vp.json
#   * conformance suite configuration files
#       conformance-suite/fapi-conformance-suite-configs/oid4vci/
#       conformance-suite/fapi-conformance-suite-configs/oid4vci-haip/
#       conformance-suite/fapi-conformance-suite-configs/oid4vp/
#
# The realms and configurations mirror the Keycloak conformance tests
# (https://github.com/keycloak/keycloak/tree/main/tests/conformance).
#
# Existing key material is reused. Pass --regenerate-keys to create new key material, e.g. when the
# certificates have expired (the OID4VCI issuer signing certificate is valid for 365 days as ISO/IEC 18013-5
# limits the validity of document signer certificates).
#
# Requires Python 3 and the 'cryptography' package. To run it without installing anything locally:
#
#   docker run --rm -v "$PWD":/work -w /work python:3.12-alpine \
#     sh -c "pip install -q cryptography && python3 utils/generate-oid4vc.py"
#
import argparse
import base64
import datetime
import hashlib
import json
import os
import secrets

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID, ObjectIdentifier

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEYCLOAK_DIR = os.path.join(BASE_DIR, "test-target", "keycloak", "keycloak")
KEY_DIR = os.path.join(KEYCLOAK_DIR, "oid4vc")
KEYSTORE_DIR = os.path.join(KEY_DIR, "keystores")
REALM_DIR = os.path.join(KEYCLOAK_DIR, "realms")
CONFIG_DIR = os.path.join(BASE_DIR, "conformance-suite", "fapi-conformance-suite-configs")

# Keycloak only loads keystores located in a folder named like the realm in its data directory
KEYSTORE_PASSWORD = "password"
KEYSTORE_PATH_IN_CONTAINER = "/opt/keycloak/data/{realm}/{filename}"
VCI_SIGNING_KEYSTORE = "oid4vci-signing.p12"
VCI_SIGNING_KEY_ALIAS = "oid4vci-conformance-signing"
VP_VERIFIER_KEYSTORE = "oid4vp-verifier.p12"
VP_VERIFIER_KEY_ALIAS = "vp_verifier_key"
# CRL of the OID4VCI credential signing CA, served by the oid4vc-crl-server service of docker-compose.yml
VCI_ISSUER_CRL_URL = "http://oid4vc-crl-server:8080/oid4vci-issuer-ca.crl"

HOLDER = "john"
REJECTING_USER = "mike"

VCI_CLIENT = "oid4vci-client"
VCI_CLIENT2 = "oid4vci-client2"
VCI_APP_CLIENT = "oid4vci-app"
SD_JWT_SCOPE = "conformance_sd_jwt_vc"
SD_JWT_KEY_ATTESTATION_SCOPE = "conformance_sd_jwt_vc_key_attestation"
MDOC_SCOPE = "conformance_mso_mdoc"
# An example doctype rather than org.iso.18013.5.1.mDL because Keycloak does not issue real mDLs and the suite
# would otherwise require all mandatory mDL data elements from ISO/IEC 18013-5 chapter 5
MDOC_DOC_TYPE = "org.example.conformance.mdoc"
MDOC_NAMESPACE = "org.example.conformance"
CLIENT_ATTESTER_TRUST_IDP = "conformance-client-attester"
ATTESTER_X509_TRUST_IDP = "conformance-attester-x509"
CLIENT_ATTESTATION_ISSUER = "https://example.com/client-attester"
HAIP_CLIENT_PROFILE = "oid4vc-haip-profile"

VP_CLIENT = "wallet-mock"
VP_TRUST_IDP = "conformance-issuer-trust"
VP_IDP = "oid4vp"
VP_ENCRYPTED_IDP = "oid4vp-encrypted"
# The suite presents a PID SD-JWT VC and discloses given_name and family_name. given_name is the principal
# because the presented credential carries no stable subject claim.
VP_DCQL_QUERY = {
    "credentials": [
        {
            "id": "pid_sd_jwt",
            "format": "dc+sd-jwt",
            "meta": {"vct_values": ["urn:eudi:pid:1"]},
            "claims": [{"path": ["given_name"]}, {"path": ["family_name"]}]
        }
    ],
    "credential_sets": [{"options": [["pid_sd_jwt"]], "required": True}]
}

VCI_ALIAS = "keycloak-oid4vci"
VP_ALIAS = "keycloak-oid4vp"

# Test plans are run in parallel when their configurations use different aliases, so every test plan has its own
# configuration with its own alias.

# (name, credential configuration, description) of the OID4VCI-HAIP test plans
HAIP_PLANS = [
    ("sd-jwt-vc", SD_JWT_SCOPE, "SD-JWT VC"),
    ("sd-jwt-vc-issuer-initiated", SD_JWT_SCOPE, "SD-JWT VC in the issuer initiated flow"),
    ("sd-jwt-vc-key-attestation", SD_JWT_KEY_ATTESTATION_SCOPE, "SD-JWT VC requiring key attestations"),
    ("mdoc", MDOC_SCOPE, "ISO mdoc"),
]

# (configuration directory, configuration file name, alias, HAIP, credential configuration, key attestation,
#  description) of the OID4VCI and OID4VCI-HAIP test plans
VCI_CONFIGS = [
    ("oid4vci", "oid4vci-sd-jwt-vc-automated.json", VCI_ALIAS, False, SD_JWT_SCOPE, False,
     "OID4VCI 1.0 Final: Keycloak test with SD-JWT VC"),
    ("oid4vci", "oid4vci-sd-jwt-vc-encrypted-automated.json", VCI_ALIAS + "-encrypted", False, SD_JWT_SCOPE, False,
     "OID4VCI 1.0 Final: Keycloak test with SD-JWT VC and encrypted credential responses"),
    ("oid4vci", "oid4vci-sd-jwt-vc-issuer-initiated-automated.json", VCI_ALIAS + "-issuer-initiated", False,
     SD_JWT_SCOPE, False, "OID4VCI 1.0 Final: Keycloak test with SD-JWT VC in the issuer initiated flow"),
    ("oid4vci", "oid4vci-sd-jwt-vc-key-attestation-automated.json", VCI_ALIAS + "-key-attestation", False,
     SD_JWT_KEY_ATTESTATION_SCOPE, True,
     "OID4VCI 1.0 Final: Keycloak test with SD-JWT VC requiring key attestations"),
    ("oid4vci", "oid4vci-mdoc-automated.json", VCI_ALIAS + "-mdoc", False, MDOC_SCOPE, False,
     "OID4VCI 1.0 Final: Keycloak test with ISO mdoc"),
] + [
    ("oid4vci-haip", "oid4vci-haip-{}-automated.json".format(name), "{}-haip-{}".format(VCI_ALIAS, name), True,
     credential_configuration_id, False, "OID4VCI 1.0 Final + HAIP: Keycloak test with {}".format(description))
    for name, credential_configuration_id, description in HAIP_PLANS
]

# (configuration file name, alias, cross device, description) of the OID4VP test plans
VP_CONFIGS = [
    ("oid4vp-sd-jwt-vc-x509-hash-automated.json", VP_ALIAS, False,
     "OID4VP 1.0 Final: Keycloak verifier test with SD-JWT VC (same device flow, direct_post)"),
    ("oid4vp-sd-jwt-vc-x509-hash-encrypted-automated.json", VP_ALIAS + "-encrypted", False,
     "OID4VP 1.0 Final: Keycloak verifier test with SD-JWT VC (same device flow, direct_post.jwt)"),
    ("oid4vp-sd-jwt-vc-x509-hash-cross-device-automated.json", VP_ALIAS + "-cross-device", True,
     "OID4VP 1.0 Final: Keycloak verifier test with SD-JWT VC (cross device flow)"),
]

# Fixed values keep the generated realm files stable between runs
CREATED_DATE = 1767225600000

# Keycloak's default user profile, with unmanaged attributes enabled for the holder's 'did' and address attributes
USER_PROFILE = {
    "attributes": [
        {"name": "username", "displayName": "${username}",
         "permissions": {"view": ["admin", "user"], "edit": ["admin", "user"]},
         "validations": {"length": {"min": 3, "max": 255}, "username-prohibited-characters": {},
                         "up-username-not-idn-homograph": {}}},
        {"name": "email", "displayName": "${email}", "required": {"roles": ["user"]},
         "permissions": {"view": ["admin", "user"], "edit": ["admin", "user"]},
         "validations": {"email": {}, "length": {"max": 255}}},
        {"name": "firstName", "displayName": "${firstName}", "required": {"roles": ["user"]},
         "permissions": {"view": ["admin", "user"], "edit": ["admin", "user"]},
         "validations": {"length": {"max": 255}, "person-name-prohibited-characters": {}}},
        {"name": "lastName", "displayName": "${lastName}", "required": {"roles": ["user"]},
         "permissions": {"view": ["admin", "user"], "edit": ["admin", "user"]},
         "validations": {"length": {"max": 255}, "person-name-prohibited-characters": {}}}
    ],
    "groups": [{"name": "user-metadata", "displayHeader": "User metadata",
                "displayDescription": "Attributes, which refer to user metadata"}],
    "unmanagedAttributePolicy": "ENABLED"
}


########################################
# Key material
########################################

def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def int_bytes(value):
    return value.to_bytes(32, "big")


def serial_number(bits):
    return secrets.randbits(bits - 1) | (1 << (bits - 2))


def certificate_builder(issuer, subject, public_key, serial_bits, days):
    now = datetime.datetime.now(datetime.timezone.utc)
    return (x509.CertificateBuilder()
            .issuer_name(issuer)
            .subject_name(subject)
            .public_key(public_key)
            .serial_number(serial_number(serial_bits))
            .not_valid_before(now - datetime.timedelta(days=1))
            .not_valid_after(now + datetime.timedelta(days=days)))


def key_usage(digital_signature=False, key_cert_sign=False, crl_sign=False):
    return x509.KeyUsage(digital_signature=digital_signature, content_commitment=False, key_encipherment=False,
                         data_encipherment=False, key_agreement=False, key_cert_sign=key_cert_sign,
                         crl_sign=crl_sign, encipher_only=False, decipher_only=False)


class SigningKey:
    """An EC P-256 key with a CA-issued certificate, stored as PEM files under KEY_DIR."""

    def __init__(self, name, kid, key, certificate, ca_certificate, ca_key=None):
        self.name = name
        self.kid = kid
        self.key = key
        self.certificate = certificate
        self.ca_certificate = ca_certificate
        # only kept for the OID4VCI credential signing CA, which issues the CRL served by oid4vc-crl-server
        self.ca_key = ca_key

    @staticmethod
    def paths(name):
        return (os.path.join(KEY_DIR, name + "-key.pem"),
                os.path.join(KEY_DIR, name + ".pem"),
                os.path.join(KEY_DIR, name + "-ca.pem"))

    @classmethod
    def load(cls, name, kid):
        key_path, cert_path, ca_path = cls.paths(name)
        with open(key_path, "rb") as f:
            key = serialization.load_pem_private_key(f.read(), password=None)
        with open(cert_path, "rb") as f:
            certificate = x509.load_pem_x509_certificate(f.read())
        with open(ca_path, "rb") as f:
            ca_certificate = x509.load_pem_x509_certificate(f.read())
        ca_key = None
        ca_key_path = os.path.join(KEY_DIR, name + "-ca-key.pem")
        if os.path.exists(ca_key_path):
            with open(ca_key_path, "rb") as f:
                ca_key = serialization.load_pem_private_key(f.read(), password=None)
        return cls(name, kid, key, certificate, ca_certificate, ca_key)

    @classmethod
    def exists(cls, name):
        return all(os.path.exists(path) for path in cls.paths(name))

    def save(self):
        key_path, cert_path, ca_path = self.paths(self.name)
        if self.ca_key is not None:
            with open(os.path.join(KEY_DIR, self.name + "-ca-key.pem"), "wb") as f:
                f.write(self.ca_key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                                  serialization.NoEncryption()))
        with open(key_path, "wb") as f:
            f.write(self.key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                           serialization.NoEncryption()))
        with open(cert_path, "wb") as f:
            f.write(self.certificate.public_bytes(serialization.Encoding.PEM))
        with open(ca_path, "wb") as f:
            f.write(self.ca_certificate.public_bytes(serialization.Encoding.PEM))

    def ca_certificate_pem(self):
        return self.ca_certificate.public_bytes(serialization.Encoding.PEM).decode("ascii")

    def x509_hash(self):
        return b64url(hashlib.sha256(self.certificate.public_bytes(serialization.Encoding.DER)).digest())

    def jwk(self, include_private_key):
        numbers = self.key.public_key().public_numbers()
        jwk = {
            "kty": "EC",
            "use": "sig",
            "crv": "P-256",
            "kid": self.kid,
            "x5c": [base64.b64encode(self.certificate.public_bytes(serialization.Encoding.DER)).decode("ascii")],
            "x": b64url(int_bytes(numbers.x)),
            "y": b64url(int_bytes(numbers.y)),
            "alg": "ES256"
        }
        if include_private_key:
            jwk["d"] = b64url(int_bytes(self.key.private_numbers().private_value))
        return jwk

    def jwks(self, include_private_key):
        return {"keys": [self.jwk(include_private_key)]}

    def write_keystore(self, filename, alias):
        os.makedirs(KEYSTORE_DIR, exist_ok=True)
        data = pkcs12.serialize_key_and_certificates(
            alias.encode("ascii"), self.key, self.certificate, [self.ca_certificate],
            serialization.BestAvailableEncryption(KEYSTORE_PASSWORD.encode("ascii")))
        with open(os.path.join(KEYSTORE_DIR, filename), "wb") as f:
            f.write(data)


def generate_conformance_signing_key(name, kid, common_name, leaf_eku):
    """Same certificate profile as ConformanceSigningKey of the Keycloak conformance tests."""
    ca_key = ec.generate_private_key(ec.SECP256R1())
    key = ec.generate_private_key(ec.SECP256R1())
    ca_name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, common_name + " CA")])
    # X509TrustMaterial rejects trust anchors that are not CA certificates
    ca_certificate = (certificate_builder(ca_name, ca_name, ca_key.public_key(), 160, 3650)
                      .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
                      .add_extension(key_usage(key_cert_sign=True, crl_sign=True), critical=True)
                      .sign(ca_key, hashes.SHA256()))
    # The key-attestation validator rejects CA-capable leaves
    builder = (certificate_builder(ca_name, x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, common_name)]),
                                   key.public_key(), 160, 3650)
               .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
               .add_extension(key_usage(digital_signature=True), critical=True))
    if leaf_eku is not None:
        builder = builder.add_extension(x509.ExtendedKeyUsage([leaf_eku]), critical=False)
    return SigningKey(name, kid, key, builder.sign(ca_key, hashes.SHA256()), ca_certificate)


def generate_vci_issuer_signing_key():
    """Same certificate profile as VciTestSigningKey of the Keycloak conformance tests, which follows the
    ISO/IEC 18013-5 certificate profiles the suite validates against."""
    ca_key = ec.generate_private_key(ec.SECP256R1())
    key = ec.generate_private_key(ec.SECP256R1())
    # ISO/IEC 18013-5 Table B.3 requires the DS certificate countryName to match the issuing_country data element
    ca_name = x509.Name([x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
                         x509.NameAttribute(NameOID.COMMON_NAME, "OID4VCI Conformance CA")])
    leaf_name = x509.Name([x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
                           x509.NameAttribute(NameOID.COMMON_NAME, "OID4VCI Conformance Issuer")])
    issuer_contact = x509.IssuerAlternativeName([x509.RFC822Name("oid4vci-conformance@example.com")])
    # the suite fetches and validates this CRL for ISO mdoc credentials, so it is served in the test environment
    crl = x509.CRLDistributionPoints([x509.DistributionPoint(
        full_name=[x509.UniformResourceIdentifier(VCI_ISSUER_CRL_URL)],
        relative_name=None, reasons=None, crl_issuer=None)])
    ca_certificate = (certificate_builder(ca_name, ca_name, ca_key.public_key(), 159, 3650)
                      .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
                      .add_extension(key_usage(key_cert_sign=True, crl_sign=True), critical=True)
                      .add_extension(x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()), critical=False)
                      .add_extension(issuer_contact, critical=False)
                      .add_extension(crl, critical=False)
                      .sign(ca_key, hashes.SHA256()))
    certificate = (certificate_builder(ca_name, leaf_name, key.public_key(), 159, 365)
                   .add_extension(key_usage(digital_signature=True), critical=True)
                   .add_extension(x509.ExtendedKeyUsage([ObjectIdentifier("1.0.18013.5.1.2")]), critical=True)
                   .add_extension(x509.SubjectKeyIdentifier.from_public_key(key.public_key()), critical=False)
                   .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
                                  critical=False)
                   .add_extension(issuer_contact, critical=False)
                   .add_extension(crl, critical=False)
                   .sign(ca_key, hashes.SHA256()))
    return SigningKey("vci-issuer", VCI_SIGNING_KEY_ALIAS, key, certificate, ca_certificate, ca_key)


KEY_SPECS = {
    # signs the issued credentials (SD-JWT VC x5c header / mdoc issuer certificate)
    "vci-issuer": lambda: generate_vci_issuer_signing_key(),
    # signs client attestations (OID4VCI-HAIP) and key attestations
    "vci-attester": lambda: generate_conformance_signing_key(
        "vci-attester", "ct_client_attester_key", "OID4VCI Conformance Attester", ExtendedKeyUsageOID.EMAIL_PROTECTION),
    # private_key_jwt client authentication keys (OID4VCI), one per client as the suite checks they differ
    "vci-client1": lambda: generate_conformance_signing_key(
        "vci-client1", "ct_client_signing_key", "OID4VCI Conformance Client", ExtendedKeyUsageOID.CLIENT_AUTH),
    "vci-client2": lambda: generate_conformance_signing_key(
        "vci-client2", "ct_client2_signing_key", "OID4VCI Conformance Client 2", ExtendedKeyUsageOID.CLIENT_AUTH),
    # signs the verifier's request objects (OID4VP), the suite also signs the presented credential with it
    "vp-verifier": lambda: generate_conformance_signing_key(
        "vp-verifier", VP_VERIFIER_KEY_ALIAS, "OID4VP Conformance Verifier", None),
}

KEY_IDS = {
    "vci-issuer": VCI_SIGNING_KEY_ALIAS,
    "vci-attester": "ct_client_attester_key",
    "vci-client1": "ct_client_signing_key",
    "vci-client2": "ct_client2_signing_key",
    "vp-verifier": VP_VERIFIER_KEY_ALIAS,
}


def load_or_generate_keys(regenerate):
    os.makedirs(KEY_DIR, exist_ok=True)
    keys = {}
    for name, generate in KEY_SPECS.items():
        if regenerate or not SigningKey.exists(name):
            print("Generating key material: " + name)
            key = generate()
            key.save()
            if name == "vci-issuer":
                key.write_keystore(VCI_SIGNING_KEYSTORE, VCI_SIGNING_KEY_ALIAS)
            elif name == "vp-verifier":
                key.write_keystore(VP_VERIFIER_KEYSTORE, VP_VERIFIER_KEY_ALIAS)
        else:
            key = SigningKey.load(name, KEY_IDS[name])
        keys[name] = key
    return keys


########################################
# Keycloak realms
########################################

def keystore_key_provider(name, realm, filename, alias, priority):
    return {
        "name": name,
        "providerId": "java-keystore",
        "subComponents": {},
        "config": {
            "priority": [str(priority)],
            "enabled": ["true"],
            "active": ["true"],
            "algorithm": ["ES256"],
            "keyUse": ["SIG"],
            "keystore": [KEYSTORE_PATH_IN_CONTAINER.format(realm=realm, filename=filename)],
            "keystorePassword": [KEYSTORE_PASSWORD],
            "keystoreType": ["PKCS12"],
            "keyAlias": [alias],
            "keyPassword": [KEYSTORE_PASSWORD]
        }
    }


def user_profile_component():
    return {
        "providerId": "declarative-user-profile",
        "subComponents": {},
        "config": {"kc.user.profile.config": [json.dumps(USER_PROFILE, separators=(",", ":"))]}
    }


def mapper(name, mapper_type, config):
    return {"name": name, "protocol": "oid4vc", "protocolMapper": mapper_type, "consentRequired": False,
            "config": config}


def sd_jwt_mappers(scope_name):
    return [
        mapper("did-mapper", "oid4vc-subject-id-mapper", {"claim.name": "id", "userAttribute": "did"}),
        mapper("email-mapper", "oid4vc-user-attribute-mapper", {"claim.name": "email", "userAttribute": "email"}),
        mapper("first-name-mapper", "oid4vc-user-attribute-mapper",
               {"claim.name": "firstName", "userAttribute": "firstName"}),
        mapper("last-name-mapper", "oid4vc-user-attribute-mapper",
               {"claim.name": "lastName", "userAttribute": "lastName"}),
        mapper("address-street-mapper", "oid4vc-user-attribute-mapper",
               {"claim.name": "address.street_address", "userAttribute": "address_street_address"}),
        mapper("address-locality-mapper", "oid4vc-user-attribute-mapper",
               {"claim.name": "address.locality", "userAttribute": "address_locality"}),
        mapper("generated-id-mapper", "oid4vc-generated-id-mapper", {"claim.name": "jti"}),
        mapper("static-scope-mapper", "oid4vc-static-claim-mapper",
               {"claim.name": "scope-name", "staticValue": scope_name}),
        mapper("issued-at-mapper", "oid4vc-issued-at-time-claim-mapper",
               {"claim.name": "iat", "truncateToTimeUnit": "HOURS", "valueSource": "COMPUTE"}),
        mapper("not-before-mapper", "oid4vc-issued-at-time-claim-mapper",
               {"claim.name": "nbf", "valueSource": "COMPUTE"}),
    ]


def mdoc_mappers():
    # mdoc claims are organised into namespaces, so every mapper pins the example namespace
    def user_attribute(name, mapper_type, claim, attribute):
        return mapper(name, mapper_type,
                      {"claim.name": claim, "userAttribute": attribute, "mdoc.namespace": MDOC_NAMESPACE})

    def static(name, claim, value):
        return mapper(name, "oid4vc-static-claim-mapper",
                      {"claim.name": claim, "staticValue": value, "mdoc.namespace": MDOC_NAMESPACE})

    return [
        user_attribute("did-mapper", "oid4vc-subject-id-mapper", "id", "did"),
        user_attribute("given-name-mapper", "oid4vc-user-attribute-mapper", "given_name", "firstName"),
        user_attribute("family-name-mapper", "oid4vc-user-attribute-mapper", "family_name", "lastName"),
        static("birth-date-mapper", "birth_date", "1986-03-22"),
        static("issue-date-mapper", "issue_date", "2019-10-20"),
        static("expiry-date-mapper", "expiry_date", "2029-10-20"),
        static("issuing-country-mapper", "issuing_country", "US"),
        static("issuing-authority-mapper", "issuing_authority", "Keycloak Conformance"),
        static("document-number-mapper", "document_number", "TEST-1234567"),
        static("un-distinguishing-sign-mapper", "un_distinguishing_sign", "USA"),
        static("portrait-mapper", "portrait", "conformance-portrait"),
        static("driving-privileges-mapper", "driving_privileges", "[]"),
    ]


def credential_scope(name, credential_format, vct, binding_method, mappers, key_attestation_required=False):
    attributes = {
        "include.in.token.scope": "true",
        "vc.format": credential_format,
        "vc.credential_build_config.hash_algorithm": "SHA-256",
        "vc.credential_build_config.sd_jwt.visible_claims": "id,iat,nbf,exp,jti",
        "vc.credential_build_config.token_jws_type": "dc+sd-jwt",
        "vc.sd_jwt.number_of_decoys": "10",
        # exp is computed from the hour-rounded iat (see the time claims strategy), so a 2 hour expiry keeps at
        # least an hour of validity at issuance
        "vc.expiry_in_seconds": "7200",
        "vc.credential_configuration_id": name,
        "vc.credential_identifier": name,
        "vc.credential_signing_alg": "ES256",
        "vc.verifiable_credential_type": vct,
        "vc.display": json.dumps([{"name": name, "locale": "en-US"}], separators=(",", ":")),
        "vc.binding_required": "true",
        "vc.binding_required_proof_types": "jwt",
        "vc.cryptographic_binding_methods_supported": binding_method,
    }
    if key_attestation_required:
        attributes["vc.key_attestations_required"] = "true"
    return {"name": name, "protocol": "oid4vc", "attributes": attributes, "protocolMappers": mappers}


def credential_scopes():
    # A urn vct (rather than an https URL) means there is no retrievable SD-JWT VC Type Metadata, so the suite
    # does not attempt to fetch it
    return [
        credential_scope(SD_JWT_SCOPE, "dc+sd-jwt", "urn:example:sd-jwt-credential", "jwk",
                         sd_jwt_mappers(SD_JWT_SCOPE)),
        # requires key attestations, used by the key attestation conformance tests
        credential_scope(SD_JWT_KEY_ATTESTATION_SCOPE, "dc+sd-jwt", "urn:example:sd-jwt-credential", "jwk",
                         sd_jwt_mappers(SD_JWT_KEY_ATTESTATION_SCOPE), key_attestation_required=True),
        # mdoc carries the doctype where SD-JWT VC carries the vct
        credential_scope(MDOC_SCOPE, "mso_mdoc", MDOC_DOC_TYPE, "cose_key", mdoc_mappers()),
    ]


def generated_secret_key_providers():
    """Keycloak's default HMAC and AES key providers of a newly created realm. Without them Keycloak generates the keys
    on the first request, and test plans running in parallel then generate several keys at the same time, which
    invalidates each other's login codes and cookies."""
    return [
        {
            "name": "hmac-generated-hs512",
            "providerId": "hmac-generated",
            "subComponents": {},
            "config": {"priority": ["100"], "enabled": ["true"], "active": ["true"], "algorithm": ["HS512"]}
        },
        {
            "name": "aes-generated",
            "providerId": "aes-generated",
            "subComponents": {},
            "config": {"priority": ["100"], "enabled": ["true"], "active": ["true"]}
        }
    ]


def user(username, first_name, last_name, realm, verifiable_credentials, consented_clients=()):
    rep = {
        "username": username,
        "enabled": True,
        "email": username + "@example.test",
        "emailVerified": True,
        "firstName": first_name,
        "lastName": last_name,
        "attributes": {
            "did": ["did:key:" + username],
            "address_street_address": ["221B Baker Street"],
            "address_locality": ["London"]
        },
        "credentials": [{"type": "password", "value": username, "temporary": False}],
        "realmRoles": ["default-roles-" + realm]
    }
    if verifiable_credentials:
        # the revision column is short, so use an id of the same length as Keycloak's generated secure ids
        rep["verifiableCredentials"] = [
            {"credentialScopeName": scope,
             "revision": b64url(hashlib.sha256((username + ":" + scope).encode("utf-8")).digest())[:22],
             "createdDate": CREATED_DATE}
            for scope in verifiable_credentials]
    if consented_clients:
        # Granted in advance, as test plans running in parallel would otherwise grant the consent at the same time,
        # which stores duplicate consents that break all later logins of the user to the client
        rep["clientConsents"] = [
            {"clientId": client_id,
             "grantedClientScopes": ["basic", "profile", "roles", "email", SD_JWT_SCOPE, SD_JWT_KEY_ATTESTATION_SCOPE,
                                     MDOC_SCOPE],
             "createdDate": CREATED_DATE,
             "lastUpdatedDate": CREATED_DATE}
            for client_id in consented_clients]
    return rep


def vci_conformance_client(args, client_id, wildcard_redirect, attributes, authenticator_type):
    # the callbacks of all the OID4VCI and OID4VCI-HAIP test plans, which run in parallel with different aliases
    return {
        "clientId": client_id,
        "enabled": True,
        "protocol": "openid-connect",
        "publicClient": False,
        "clientAuthenticatorType": authenticator_type,
        "standardFlowEnabled": True,
        "implicitFlowEnabled": False,
        "serviceAccountsEnabled": False,
        "directAccessGrantsEnabled": False,
        # consent is required so that the user can reject the authorization (user-rejects-authentication test)
        "consentRequired": True,
        "redirectUris": ["https://{}/test/a/{}/callback{}".format(args.suite_host, alias, "*" if wildcard_redirect else "")
                         for alias in sorted({spec[2] for spec in VCI_CONFIGS})],
        "webOrigins": ["https://" + args.suite_host],
        "defaultClientScopes": ["basic", "profile", "roles"],
        "optionalClientScopes": [SD_JWT_SCOPE, SD_JWT_KEY_ATTESTATION_SCOPE, MDOC_SCOPE, "email"],
        "attributes": dict({"oid4vci.enabled": "true"}, **attributes)
    }


def vci_app_client(args):
    # the application the holder logs in to for creating credential offers (issuer initiated flow)
    return {
        "clientId": VCI_APP_CLIENT,
        "enabled": True,
        "protocol": "openid-connect",
        "publicClient": True,
        "standardFlowEnabled": True,
        "serviceAccountsEnabled": False,
        "directAccessGrantsEnabled": False,
        "redirectUris": [kc_url(args, "account/*")],
        "defaultClientScopes": ["basic", "profile", "roles"]
    }


def attester_x509_trust_idp(keys):
    # key attestations carry an x5c chain, validated against this X.509 trust domain
    return {
        "alias": ATTESTER_X509_TRUST_IDP,
        "providerId": "default-trust",
        "enabled": True,
        "config": {
            "useX509": "true",
            "trustedCertificates": keys["vci-attester"].ca_certificate_pem(),
            # the attester leaf certificate is generated with the emailProtection extended key usage
            "requiredExtendedKeyUsages": "1.3.6.1.5.5.7.3.4"
        }
    }


def vci_realm(args, keys, haip):
    realm = {
        "realm": args.realm,
        "enabled": True,
        "sslRequired": "external",
        "eventsEnabled": True,
        "eventsListeners": ["jboss-logging"],
        "verifiableCredentialsEnabled": True,
        "defaultSignatureAlgorithm": "ES256",
        "attributes": {
            # create the default client scopes (basic, profile, roles, email, ...) besides the credential scopes
            "CreateDefaultClientScopes": "true",
            # the conformance suite wallet requests DEF-compressed encrypted credential responses
            "oid4vci.request.zip.algorithms": "DEF",
            # round credential time claims (iat/exp/nbf) so two credentials do not carry the precise issuance
            # time, which the suite's unlinkability check (RFC 9901 10.1) warns on
            "oid4vci.time.claims.strategy": "ROUND",
            "oid4vci.time.round.unit": "HOUR",
            # advertises batch_credential_issuance, used by the batch issuance test
            "oid4vci.batch_credential_issuance.batch_size": "20",
            # short request_uri lifespan for the expired request_uri test
            "parRequestUriLifespan": "15"
        },
        "clientScopes": credential_scopes(),
        "users": [
            user(HOLDER, "John", "Doe", args.realm, [SD_JWT_SCOPE, SD_JWT_KEY_ATTESTATION_SCOPE, MDOC_SCOPE],
                 consented_clients=[VCI_CLIENT, VCI_CLIENT2]),
            # rejects the authorization in the consent screen (user-rejects-authentication test)
            user(REJECTING_USER, "Mike", "Doe", args.realm, [])
        ],
        "components": {
            "org.keycloak.keys.KeyProvider": generated_secret_key_providers() + [
                keystore_key_provider("oid4vci-conformance-signing-key", args.realm, VCI_SIGNING_KEYSTORE,
                                      VCI_SIGNING_KEY_ALIAS, 0),
                # the conformance suite wallet requests ECDH-ES encrypted credential responses
                {
                    "name": "oid4vci-conformance-ecdh-encryption-key",
                    "providerId": "ecdh-generated",
                    "subComponents": {},
                    "config": {
                        "priority": ["0"],
                        "enabled": ["true"],
                        "active": ["true"],
                        "ecdhAlgorithm": ["ECDH-ES"],
                        "ecdhEllipticCurveKey": ["P-256"]
                    }
                }
            ],
            "org.keycloak.userprofile.UserProfileProvider": [user_profile_component()]
        }
    }
    if haip:
        # attestation based client authentication against the trust IDPs plus DPoP sender constraining
        attributes = {
            "attester_trust_idps": CLIENT_ATTESTER_TRUST_IDP,
            "oid4vci.attester_trust_idps": CLIENT_ATTESTER_TRUST_IDP + "," + ATTESTER_X509_TRUST_IDP,
            "dpop.bound.access.tokens": "true"
        }
        realm["clients"] = [
            vci_conformance_client(args, VCI_CLIENT, False, attributes, "attestation-based"),
            vci_conformance_client(args, VCI_CLIENT2, True, attributes, "attestation-based"),
            vci_app_client(args)
        ]
        realm["identityProviders"] = [
            {
                "alias": CLIENT_ATTESTER_TRUST_IDP,
                "providerId": "default-trust",
                "enabled": True,
                "config": {"publicKeySignatureVerifier": json.dumps(keys["vci-attester"].jwks(False),
                                                                    separators=(",", ":"))}
            },
            attester_x509_trust_idp(keys)
        ]
        # OpenID4VC High Assurance Interoperability Profile 1.0: SecurePAR, no implicit grant, PKCE enforced
        realm["clientProfiles"] = {"profiles": [{
            "name": HAIP_CLIENT_PROFILE,
            "description": "Enforces the OpenID4VC High Assurance Interoperability Profile 1.0",
            "executors": [
                {"executor": "secure-par-content", "configuration": {}},
                {"executor": "reject-implicit-grant", "configuration": {"auto-configure": False}},
                {"executor": "pkce-enforcer", "configuration": {"auto-configure": False}}
            ]
        }]}
        realm["clientPolicies"] = {"policies": [{
            "name": "oid4vc-haip-policy",
            "description": "Enables the oid4vc-haip-profile for OID4VCI clients",
            "enabled": True,
            "conditions": [{
                "condition": "client-attributes",
                "configuration": {"attributes": json.dumps([{"key": "oid4vci.enabled", "value": "true"}],
                                                           separators=(",", ":"))}
            }],
            "profiles": [HAIP_CLIENT_PROFILE]
        }]}
    else:
        # private_key_jwt client authentication plus DPoP sender constraining
        def attributes(key):
            return {
                "use.jwks.string": "true",
                "jwks.string": json.dumps(key.jwks(False), separators=(",", ":")),
                # required for the key attestation tests
                "oid4vci.attester_trust_idps": ATTESTER_X509_TRUST_IDP,
                "dpop.bound.access.tokens": "true"
            }

        realm["clients"] = [
            vci_conformance_client(args, VCI_CLIENT, False, attributes(keys["vci-client1"]), "client-jwt"),
            vci_conformance_client(args, VCI_CLIENT2, True, attributes(keys["vci-client2"]), "client-jwt"),
            vci_app_client(args)
        ]
        realm["identityProviders"] = [attester_x509_trust_idp(keys)]
    return realm


def vp_realm(args, keys):
    def vp_idp(alias, response_mode):
        config = {
            # trusts the presented credential's x5c certificate chain against the conformance CA
            "trustMaterialIdps": VP_TRUST_IDP,
            "dcqlQuery": json.dumps(VP_DCQL_QUERY, indent=2),
            "principalAttribute": "given_name"
        }
        if response_mode:
            config["responseMode"] = response_mode
        return {
            "alias": alias,
            "providerId": "oid4vp",
            "enabled": True,
            "firstBrokerLoginFlowAlias": "first broker login",
            "config": config
        }

    return {
        "realm": args.realm,
        "enabled": True,
        "sslRequired": "external",
        "eventsEnabled": True,
        "eventsListeners": ["jboss-logging"],
        "clients": [{
            "clientId": VP_CLIENT,
            "enabled": True,
            "protocol": "openid-connect",
            "publicClient": True,
            "standardFlowEnabled": True,
            "directAccessGrantsEnabled": False,
            "redirectUris": ["*"]
        }],
        "identityProviders": [
            {
                "alias": VP_TRUST_IDP,
                "providerId": "default-trust",
                "enabled": True,
                "config": {"useX509": "true", "trustedCertificates": keys["vp-verifier"].ca_certificate_pem()}
            },
            # direct_post response mode
            vp_idp(VP_IDP, None),
            # direct_post.jwt (encrypted) response mode
            vp_idp(VP_ENCRYPTED_IDP, "direct_post.jwt")
        ],
        "components": {
            "org.keycloak.keys.KeyProvider": generated_secret_key_providers() + [
                # the verifier's request object signing key, holding the CA-issued certificate the suite trusts
                keystore_key_provider("oid4vp-verifier-signing-key", args.realm, VP_VERIFIER_KEYSTORE,
                                      VP_VERIFIER_KEY_ALIAS, 100)
            ]
        }
    }


########################################
# Conformance suite configurations
########################################

def kc_base_url(args):
    return "https://{}{}".format(args.kc_host, args.kc_path.rstrip("/"))


def kc_url(args, path):
    return "{}/realms/{}/{}".format(kc_base_url(args), args.realm, path)


def callback_url(args, alias):
    return "https://{}/test/a/{}/callback*".format(args.suite_host, alias)


def login_task(args, username, optional=True):
    task = {
        "task": "Initial login",
        "match": kc_url(args, "login-actions/authenticate*"),
        "optional": optional,
        "commands": [
            ["text", "id", "username", username],
            ["text", "id", "password", username],
            ["click", "name", "login"]
        ]
    }
    return task


def consent_task(args, accept=True):
    return {
        "task": "Authorize Client" if accept else "Authorize Client - not allow grant to reject an authentication flow",
        "match": kc_url(args, "login-actions/required-action*"),
        "optional": accept,
        "commands": [["click", "name", "accept" if accept else "cancel"]]
    }


def verify_complete_task(args, alias, optional=False):
    task = {
        "task": "Verify Complete",
        "match": callback_url(args, alias),
        "commands": [["wait", "id", "submission_complete", 10]]
    }
    if optional:
        task["optional"] = True
    return task


def error_page_task(args, message):
    return {
        "task": "Expect Keycloak error page",
        "match": kc_url(args, "protocol/openid-connect/auth*"),
        "commands": [["wait", "id", "kc-error-message", 10, ".*" + message + ".*", "update-image-placeholder"]]
    }


def login_flow(args, alias):
    # the login is optional as later authorizations reuse the SSO session
    return {
        "match": kc_url(args, "protocol/openid-connect/auth*"),
        "tasks": [login_task(args, HOLDER), consent_task(args), verify_complete_task(args, alias)]
    }


def error_page_flow(args, message):
    return {"match": kc_url(args, "protocol/openid-connect/auth*"), "tasks": [error_page_task(args, message)]}


def haip_fapi2_overrides(args, alias):
    """Browser interactions of the FAPI 2.0 Security Profile tests included in the OID4VCI-HAIP test plan which
    differ from the default login, see the tests under vci/haip/fapi2 of the Keycloak conformance tests."""
    auth = kc_url(args, "protocol/openid-connect/auth*")
    return {
        "fapi2-security-profile-final-user-rejects-authentication": {"browser": [{
            "match": auth,
            "tasks": [login_task(args, REJECTING_USER), consent_task(args, accept=False),
                      verify_complete_task(args, alias)]
        }]},
        "fapi2-security-profile-final-par-attempt-to-use-expired-request_uri": {"browser": [
            error_page_flow(args, "Invalid Request")]},
        "fapi2-security-profile-final-par-attempt-to-use-request_uri-for-different-client": {"browser": [
            error_page_flow(args, "Invalid Request")]},
        "fapi2-security-profile-final-state-only-outside-request-object-not-used": {"browser": [
            error_page_flow(args, "PAR request did not include query parameter")]},
        "fapi2-security-profile-final-ensure-unsigned-authorization-request-without-using-par-fails": {"browser": [
            error_page_flow(args, "PAR request_uri not included")]},
        "fapi2-security-profile-final-par-attempt-reuse-request_uri": {"browser": [
            dict({"comment": "first authorization request with the request_uri: normal login", "match-limit": 1},
                 **login_flow(args, alias)),
            dict({"comment": "second authorization request reusing the same request_uri: expect an error page"},
                 **error_page_flow(args, "PAR not found, not issued or used multiple times"))
        ]},
        "fapi2-security-profile-final-par-ensure-reused-request-uri-prior-to-auth-completion-succeeds": {"browser": [
            {
                "comment": "first visit to the authorization endpoint: only open the login page, do not log in",
                "match": auth,
                "match-limit": 1,
                "tasks": [{
                    "task": "Load login page without authenticating",
                    "match": kc_url(args, "login-actions/authenticate*"),
                    "commands": [["wait", "id", "username", 10]]
                }]
            },
            dict({"comment": "second visit reusing the same request_uri: log in"}, **login_flow(args, alias))
        ]}
    }


def vci_config(args, keys, alias, haip, description, credential_configuration_id, key_attestation=False,
               overrides=None):
    vci = {
        "credential_issuer_url": "{}/realms/{}".format(kc_base_url(args), args.realm),
        "credential_configuration_id": credential_configuration_id
    }
    if haip:
        vci["client_attestation_issuer"] = CLIENT_ATTESTATION_ISSUER
        vci["client_attester_keys_jwks"] = keys["vci-attester"].jwks(True)
    if haip or key_attestation:
        vci["key_attestation_jwks"] = keys["vci-attester"].jwks(True)
    client = {"client_id": VCI_CLIENT}
    client2 = {"client_id": VCI_CLIENT2}
    if not haip:
        client["jwks"] = keys["vci-client1"].jwks(True)
        client2["jwks"] = keys["vci-client2"].jwks(True)
    config = {
        "alias": alias,
        "description": description,
        "vci": vci,
        "credential": {
            "trust_anchor_pem": keys["vci-issuer"].ca_certificate_pem(),
            "status_list_trust_anchor_pem": keys["vci-issuer"].ca_certificate_pem()
        },
        "client": client,
        "client2": client2,
        "browser": [login_flow(args, alias)],
        # used by oid4vc-interaction.py to create a credential offer for the issuer initiated flow
        "interaction": {
            "keycloak_url": kc_base_url(args),
            "realm": args.realm,
            "username": HOLDER,
            "password": HOLDER,
            "credential_offer_client_id": VCI_APP_CLIENT
        }
    }
    if overrides:
        config["override"] = overrides
    return config


def vp_config(args, keys, alias, description, cross_device):
    evidence_url = "https://{}/test/a/{}/verification-evidence".format(args.suite_host, alias)
    return {
        "alias": alias,
        "description": description,
        "publish": "private",
        "client": {
            "client_id": "x509_hash:" + keys["vp-verifier"].x509_hash(),
            "request_object_trust_anchor_pem": keys["vp-verifier"].ca_certificate_pem()
        },
        "credential": {"signing_jwk": keys["vp-verifier"].jwk(True)},
        # Since the suite 5.2.2 a 2xx at the response_uri no longer proves verification as the specification
        # allows deferring it, so positive verifier tests wait for screenshot evidence and finish as REVIEW.
        # The suite serves this page itself as a stand in for that screenshot.
        "browser": [{
            "match": evidence_url,
            "tasks": [{
                "task": "Capture verification evidence",
                "match": evidence_url,
                "commands": [["wait", "xpath", "//*", 10, ".*Deferred verification evidence.*",
                              "update-image-placeholder"]]
            }]
        }],
        # used by oid4vc-interaction.py to start a Keycloak login with the OID4VP identity provider and to hand the
        # resulting authorization request over to the suite's wallet
        "interaction": {
            "keycloak_url": kc_base_url(args),
            "realm": args.realm,
            "client_id": VP_CLIENT,
            "identity_providers": {"direct_post": VP_IDP, "direct_post.jwt": VP_ENCRYPTED_IDP},
            "cross_device": cross_device
        }
    }


def write_json(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="\n") as f:
        json.dump(content, f, indent=4)
        f.write("\n")
    print("Generated " + os.path.relpath(path, BASE_DIR))


def main():
    parser = argparse.ArgumentParser(description="Generates OID4VCI/OID4VCI-HAIP/OID4VP conformance test files")
    parser.add_argument("--kc-host", default="as.keycloak-fapi.org", help="Hostname of Keycloak server")
    parser.add_argument("--suite-host", default="conformance-suite.keycloak-fapi.org",
                        help="Hostname of the conformance suite server")
    # The OID4VCI conformance tests fetch the credential issuer metadata from /.well-known/openid-credential-issuer
    # followed by the issuer path, so Keycloak must serve the root path (KEYCLOAK_HTTP_RELATIVE_PATH=/)
    parser.add_argument("--kc-path", default="", help="HTTP relative path of Keycloak server, e.g. /auth")
    parser.add_argument("--realm", default="test", help="Realm name")
    parser.add_argument("--regenerate-keys", action="store_true", help="Generate new key material")
    args = parser.parse_args()

    keys = load_or_generate_keys(args.regenerate_keys)

    write_json(os.path.join(REALM_DIR, "realm-oid4vci.json"), vci_realm(args, keys, haip=False))
    write_json(os.path.join(REALM_DIR, "realm-oid4vci-haip.json"), vci_realm(args, keys, haip=True))
    write_json(os.path.join(REALM_DIR, "realm-oid4vp.json"), vp_realm(args, keys))

    for config_dir, filename, alias, haip, credential_configuration_id, key_attestation, description in VCI_CONFIGS:
        write_json(os.path.join(CONFIG_DIR, config_dir, filename), vci_config(
            args, keys, alias, haip, description, credential_configuration_id, key_attestation=key_attestation,
            # the FAPI 2.0 Security Profile tests are only part of the OID4VCI-HAIP test plans
            overrides=haip_fapi2_overrides(args, alias) if haip else None))

    for filename, alias, cross_device, description in VP_CONFIGS:
        write_json(os.path.join(CONFIG_DIR, "oid4vp", filename), vp_config(args, keys, alias, description, cross_device))


if __name__ == "__main__":
    main()
