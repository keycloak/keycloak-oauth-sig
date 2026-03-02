#!/usr/bin/env python3
"""
Generate a client_assertion JWT for Private Key JWT (client-jwt) authentication.

Usage:
    python3 generate_client_assertion.py <client_id> <token_endpoint_url>

Output:
    Prints the signed JWT to stdout.

The private key is the ES256 key embedded in the openid4vc-rest-api-jwt client config.
"""

import sys
import time
import uuid
import jwt
from cryptography.hazmat.primitives.asymmetric import ec
import base64


def base64url_decode(s: str) -> bytes:
    """Decode a base64url-encoded string."""
    rem = len(s) % 4
    if rem > 0:
        s += "=" * (4 - rem)
    return base64.urlsafe_b64decode(s)


def build_ec_private_key(d: str, x: str, y: str):
    """Build an EC private key from JWK parameters."""
    d_int = int.from_bytes(base64url_decode(d), byteorder="big")
    return ec.derive_private_key(d_int, ec.SECP256R1())


def generate_client_assertion(client_id: str, token_endpoint: str) -> str:
    """Generate a signed JWT client assertion for private_key_jwt auth."""

    # Private key from the openid4vc-rest-api-jwt client JWKS
    jwk = {
        "kty": "EC",
        "d": "r2deoeF9-z2HBVu_a3heMMZWqQbjxjT0lteb5Oxv26o",
        "crv": "P-256",
        "kid": "key-1",
        "x": "dKVClk-IZHYl4yRaJEdwZApmUzrAPtwanixXFiwm8bA",
        "y": "nSCAlmtHGg2V_bZEvJfezn6oVBvJ7Hc-Sql5go7oTHw",
        "alg": "ES256"
    }

    private_key = build_ec_private_key(jwk["d"], jwk["x"], jwk["y"])

    now = int(time.time())
    payload = {
        "iss": client_id,
        "sub": client_id,
        "aud": token_endpoint,
        "iat": now,
        "exp": now + 300,  # 5 minute expiry
        "jti": str(uuid.uuid4()),
    }

    headers = {
        "kid": jwk["kid"],
        "alg": "ES256",
    }

    token = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    return token


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(
            "Usage: python3 generate_client_assertion.py <client_id> <token_endpoint_url>",
            file=sys.stderr,
        )
        sys.exit(1)

    client_id = sys.argv[1]
    token_endpoint = sys.argv[2]

    assertion = generate_client_assertion(client_id, token_endpoint)
    print(assertion, end="")
