# Setting Up an ES256 PKCS#12 Keystore for Keycloak using OpenSSL

This guide details the step-by-step process of creating an ECDSA P-256 (ES256) private key, generating a PKCS#10 Certificate Signing Request (CSR) for an external Certificate Authority (CA), and bundling the resulting signed certificate into a PKCS#12 keystore.

---

## Step 1: Generate the EC Private Key (P-256)

Generate an unencrypted ECDSA private key using the `prime256v1` curve (NIST P-256 / secp256r1):

```bash
openssl ecparam -name prime256v1 -genkey -noout -out priv.pem
chmod 600 priv.pem
```

- **`priv.pem`**: The private key file. Kept secure and restricted to read permissions.

---

## Step 2: Generate the PKCS#10 Certificate Signing Request (CSR)

Create the CSR to submit to your external Certificate Authority. Replace the subject information with your organization's details.

```bash
openssl req -new \
  -key priv.pem \
  -out cert.csr \
  -subj "/CN=adorsys/O=adorsys/C=DE"
```

- **`cert.csr`**: Send this file to your external CA for signing.

---

## Step 3: Package Key and CA-Signed Certificate into PKCS#12

Once your CA issues the signed certificate (`cert.pem`), bundle it together with your private key (and optionally the intermediate/root CA chain `ca-cert.pem`) into a PKCS#12 (`.p12`) file.

```bash
openssl pkcs12 -export \
  -in cert.pem \
  -inkey priv.pem \
  -certfile ca-cert.pem \
  -out keystore.p12 \
  -name ecdsa-key \
  -passout pass:changeit
```

- **`keystore.p12`**: The generated PKCS#12 file to mount into Keycloak.
- **`-name ecdsa-key`**: The key alias name that must match Keycloak's **Key Alias** configuration.
- **`-passout pass:changeit`**: Password protecting the PKCS#12 file.

---

## Step 4: Verify the PKCS#12 Keystore

Inspect the generated `.p12` file to verify that the private key and certificate chain are correctly stored under the expected alias:

```bash
openssl pkcs12 -info -in keystore.p12 -passin pass:changeit -noout
```

---

## Step 5: Configure Keycloak Admin UI

1. Mount or copy `keystore.p12` to the Keycloak container/server (e.g., `/opt/keycloak/data/keystores/keystore.p12`).
2. Open the Keycloak Admin Console.
3. Navigate to **Realm Settings** → **Keys** → **Providers** → **Add provider** → **java-keystore**.
4. Configure the parameters as follows:

| Field                 | Value                                       |
| :-------------------- | :------------------------------------------ |
| **Name**              | `ecdsa-keystore`                       |
| **Priority**          | `100` (or higher than current default key)  |
| **Enabled**           | **On**                                      |
| **Active**            | **On**                                      |
| **Algorithm**         | `ES256`                                     |
| **Keystore**          | `/opt/keycloak/data/keystores/keystore.p12` |
| **Keystore Password** | `changeit`                                  |
| **Keystore Type**     | `PKCS12`                                    |
| **Key Alias**         | `ecdsa-key`                                 |
| **Key Password**      | `changeit`                                  |
| **Key use**           | `sig`                                       |

5. Click **Save**.
