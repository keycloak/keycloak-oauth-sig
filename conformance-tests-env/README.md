# Automated Conformance Test Run Environment

## How to run FAPI Conformance suite with Keycloak server in your local machine

### Software requirements

* [Docker CE](https://docs.docker.com/install/)
* [Docker Compose](https://docs.docker.com/compose/)
* JDK and [Maven](https://maven.apache.org/)

#### Supported Docker Compose Version

It has been confirmed that this automated FAPI conformance test run environment works with docker-compose version 2.40.3.

### Run FAPI Conformance suite, Keycloak server and Test Runner

Edit `hosts` file as per the [Modify your hosts file](#Modify-your-hosts-file) section

This repository contains default self-signed certificates for HTTPS, client private keys, Keycloak Realm JSON and FAPI Conformance suite config JSONs.
If you would like to use the configurations as it is, you only need to build and boot all the containers using Docker Compose.

Run the following command from the project basedir to start the test suite

```
docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```
The OpenID FAPI Conformance test interface will then be reachable at [https://localhost:8443](https://localhost:8443).
See instructions in [Run FAPI Conformance test plan](#Run-FAPI-Conformance-test-plan) 
section for running the tests manually in your browser.

To stop all containers after the automated tests have run:

```
docker-compose -p keycloak-fapi -f docker-compose.yml up --build --exit-code-from test_runner
```

The following options can be set as environment variables before the above command:

* `KEYCLOAK_BASE_IMAGE` (default: quay.io/keycloak/keycloak:17.0.1)
    * The keycloak image version used in the test suite
* `KEYCLOAK_REALM_IMPORT_FILENAME` (default: realm.json)
    * The keycloak realm import filename. Set this to `realm.json` if you are running the tests
    against a local build of keycloak.
* `AUTOMATE_TESTS` (default: true)
    * Set to false to stop conformance-suite tests automatically running
* `MVN_HOME` (default: ~/.m2)
    * Set to use a custom maven home path
* `OPENID_GIT_TAG` (default: release-v4.1.41)
    * The OpenID Conformance Suite Git Tag to be cloned    


**Example:**
```
KEYCLOAK_BASE_IMAGE=keycloak:23.0.1 docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

To stop and remove all containers, run the following:
```
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```
Instead of this, if you want also to remove all the images and the volumes created by the docker-compose in addition to containers, you run this:
```
docker-compose -p keycloak-fapi -f docker-compose.yml down --rmi local -v
```

### Modify your `hosts` file

To access to Keycloak and Resource server with FQDN, modify your `hosts` file in your local machine as follows.

```
127.0.0.1 as.keycloak-fapi.org aes.keycloak-fapi.org rs.keycloak-fapi.org cs.keycloak-fapi.org conformance-suite.keycloak-fapi.org
```

### Run FAPI Conformance test plan manually

1. Run this project with `AUTOMATE_TESTS=false` environment variable set
2. Open https://conformance-suite.keycloak-fapi.org
3. Click `Create a new test plan` button.
4. Choose `FAPI1-Advanced-Final: Authorization server test` or `FAPI-RW-ID2 (and OpenBankingUK): Authorization server test (latest version)` as Test Plan.
The `FAPI1-Advanced-Final` is currently recommended as it tests against the Final version of the FAPI specification
5. Choose `Client Authentication Type` you want to test.
6. Choose `plain_fapi` as FAPI Profile.
7. Choose `plain_response` as FAPI Response Mode.
8. Click `JSON` tab and paste content of the configuration.
  * If you want to use private_key_jwt client authentication, use [fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-PS256-PS256.json](./fapi-conformance-suite-configs/fapi1-advanced-final-with-private-key-PS256-PS256.json) or [fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-private-key-ES256-ES256.json](./fapi-conformance-suite-configs/fapi1-advanced-final-with-private-key-ES256-ES256.json).
  * If you want to use mtls client authentication, use [fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-PS256-PS256.json](./fapi-conformance-suite-configs/fapi1-advanced-final-with-mtls-PS256-PS256.json) or [fapi-conformance-suite-configs/fapi1-advanced/fapi1-advanced-final-with-mtls-ES256-ES256.json](./fapi-conformance-suite-configs/fapi1-advanced-final-with-mtls-ES256-ES256.json).
9. Click `Create Test Plan` button and follow the instructions.
10. If you used `FAPI1-Advanced-Final`, it is recommended to use Keycloak global builtin client profile `fapi-1-advanced`. To do this, you can login to Keycloak admin console (should be available
usually under `https://as.keycloak-fapi.org/auth`) as admin/admin. Then go to Realm  `Test` -> `Client Policies` -> `Policies` -> `fapi-1-0-policy`. Then add `fapi-1-advanced`. 
1.  To proceed with the tests, you can authenticate using `john` account with password `john`.
2.  When rejecting authentication scenario, you can use `mike` account with password `mike`. In this case, you need to click `No` button to cancel the authentication in the consent screen.
Before running this reject authentication test (Usually 3rd test in the conformance testsuite called something like `fapi1-advanced-final-user-rejects-authentication`),
it is recommended to login to Keycloak admin console as admin/admin and remove the existing session of user `john`. Alternative is to run this test in different browser
or clear cookies for Keycloak server.


### Run FAPI Conformance test plan manually against the online conformance testsuite

To obtain the certification, it is needed to run the conformance testsuite against the online production instance available on
https://www.certification.openid.net/ . You can still use the Keycloak server, Resource server and other utilities provided by this project
to help setup the environment needed for the conformance testsuite.

The configuration assumes that your laptop, where you are running the instance, is accessible through the internet, so that clients used
by conformance testsuite can connect to it. Simple setup assumes that your server is accessible for example on `85-244-72-90.nip.io` and
you have 2 ports opened:
  * Port 543 where Keycloak server will listen. So URL of Keycloak might be like https://85-244-72-90.nip.io:543/auth
  * Port 443 where Resource server will listen. So URL of Resource server might be like https://85-244-72-90.nip.io:443
If you use different ports, please adjust your haproxy configuration for the frontends under `load-balancer/haproxy_two-frontends.cfg`.  

The setup for this scenario is like:

1. Setup environment variables something like this. It assumes that 85.244.72.90 is your public IP and the 192.168.0.101 is the IP
of your laptop in the private local network. The introspection endpoint, which is triggered by the resource server, needs to call
Keycloak server under this private network. At least in my environment the access through public network did not work. But this 
can be environment specific. During troubles with calling introspection endpoint, you can later try to connect to api-gateway-nginx
docker container and verify with `curl` command what servers are accessible from this container.
So adjust your configuration according your environment if needed:
```
export AUTOMATE_TESTS=false
export KEYCLOAK_FQDN=85-244-72-90.nip.io
export KEYCLOAK_FRONTEND_URL=https://85-244-72-90.nip.io:543/auth
export KEYCLOAK_INTROSPECTION_ENDPOINT_FROM_API_GATEWAY=https://192-168-0-101.nip.io:543/auth/realms/test/protocol/openid-connect/token/introspect
export RESOURCE_FQDN=84-244-72-90.nip.io
```    
2. Re-generate server certificates to match the hostnames of your environment. You can use command like this and possibly change the second host according your laptop address:
```
https/generate-server.sh $KEYCLOAK_FQDN 192-168-0-101.nip.io
```
3. In case you use local built Keycloak instance as described below, it is recommended to delete the Keycloak directory and unzip new directory
to make sure that certificates from previous step will be correctly copied to the server. Also make sure that customizations for CIBA and
well-known endpoint are manually done since you use your own Docker volume (See [Keycloak dockerfile](./keycloak/Dockerfile) for the details)
4. It is needed to comment the RESOURCE_FQDN in the `docker-compose.yml` file in the load_balancer network section. Something like this:
```
networks:
  default:
    aliases:
     - ${KEYCLOAK_FQDN}
     #  - ${RESOURCE_FQDN}
     - ${CONFORMANCE_SUITE_FQDN}
```
5. In the `loadbalancer/Dockerfile`, it may be needed to switch the configuration file of the loadbalancer. Something like this:
```
# RUN /bin/sh -c "cp /tmp/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg"
RUN /bin/sh -c "cp /tmp/haproxy_two-frontends.cfg /usr/local/etc/haproxy/haproxy.cfg"
```
6. If you manually run CIBA tests, some manual changes are needed in the `auth_entity_server/main.go` to change the server name.
Especially it is needed to change the ServerName in TLS Client Config to use IP of your laptop, which can be accessed from the local network. Something like this:
```
ServerName:         "192-168-0-101.nip.io",
```
Same applies for the URL of the Keycloak Backchannel Authentication Callback Endpoint, which may also need to be changed to something like this:
```
u := "https://192-168-0-101.nip.io:543/auth/realms/test/protocol/openid-connect/ext/ciba/auth/callback/"
```
7. Rebuild and restart whole docker-compose environment as described above.
8. Follow the steps for the `Run FAPI Conformance test plan manually` described above. With the exception, that:
  * You need to use online instance of the conformance testsuite from https://www.certification.openid.net/
  * After importing the client configurations from the `fapi-conformance-suite-configs` directory, you may need to replace the URLs of
  the keycloak server like using `as.keycloak-fapi.org` with your publicly available Keycloak instance like `https://85-244-72-90.nip.io:543/auth/...`.
  Same applies for the resource server URL, which is `rs.keycloak-fapi.org` and CIBA approval endpoint, which is `aes.keycloak-fapi.org` in the configuration files by default. These needs to be replaced with your publicly available one.
9. In case you test with CIBA Ping mode, you need to login to Keycloak admin console before the test and manually change the
property `CIBA Backchannel Client Notification Endpoint` of the following clients (in case you use PS256 algorithm):
```
client1-mtls-PS256-PS256-fapi-ciba-ping-id1
client1-private_key_jwt-PS256-PS256-fapi-ciba-ping-id1
client2-mtls-PS256-PS256-fapi-ciba-ping-id1
client2-private_key_jwt-PS256-PS256-fapi-ciba-ping-id1
```
to the URL of certification testsuite itself, which is something like `https://www.certification.openid.net/test/a/keycloak/ciba-notification-endpoint`.
See the instructions for additional details: https://openid.net/certification/fapi_ciba_op_testing/ 

## For Developers

**Currently, generators of all configurations are written with bash script and some CLI tools for linux-amd64.**

Run `generate-all.sh` script simply to generate self-signed certificates for HTTPS, client private keys, Keycloak Realm JSON and FAPI Conformance suite config JSONs.

```
./generate-all.sh
```

Now, you can boot a Keycloak server with new configurations.

```
docker-compose -p keycloak-fapi -f docker-compose.yml up --force-recreate
```

## Run FAPI Conformance test against local built keycloak

If you would like to run FAPI Conformance test against local built keycloak, modify `docker-compose.yml` as follows.

```
@@ -28,6 +28,7 @@ services:
      - ./common/https/server.pem:/etc/x509/https/tls.crt
      - ./common/https/server-key.pem:/etc/x509/https/tls.key
      - ./common/https/client-ca.pem:/etc/x509/https/client-ca.crt
+     - <path to locally built keycloak>:/opt/keycloak
     ports:
      - "8787:8787"
     environment:
```

It overrides the keycloak of the base image with the one built on the local machine.

Then run the FAPI Conformance Suite with KEYCLOAK_REALM_IMPORT_FILENAME env var:

```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-local.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

## Run FAPI Conformance test with persistent OpenID Server DB volume

Running this test suite does not require a persistent storage volume for MongoDB. The main benefit of
using persistent volume storage is that the OpenID Conformance Suite will remember the last test plan
config you used, allowing for easier and faster manual test operation. If you wish to enable persistent volume storage for the MongoDB container, uncomment 
the following lines in ./docker-compose.yml

```
...
#    volumes:
#     - mongodata:/data/db
...
#volumes:
#  mongodata:
```

## Custom files in the conformance suite

The conformance-suite folder within this repository is a local copy of OpenIds FAPI conformance suite (https://gitlab.com/openid/conformance-suite/).
Incorporating the suite and running the conformance tests within docker-compose requires adding custom files into the base OpenId FAPI conformance suite.
Below is a list of the custom files currently used by the base conformance-suite.
* /conformance-suite/run-tests.sh
  * Script for running / creating test plans
* /conformance-suite/Dockerfile
  * Dockerfile which installs python dependencies, exposes ports and kicks off building the project via the server-entrypoint script 
* /conformance-suite/server-entrypoint.sh
  * Script for building the project with maven

## Run specified FAPI Conformance test

You can choose and run automatically several types of FAPI conformance test against both released keycloak container from quay.io or one you've installed on your local environment.

To do so, you need to set to the environment variable `TEST_PLAN` the value shown in the following table.

**Certified Financial-grade API (FAPI) OpenID Providers**

**Financial-grade API (FAPI) 1.0 Final**

**FAPI 1 Advanced Final (Generic)**

|Conformance Profile|Test Plan|client_auth_type|fapi_profile|fapi_response_mode|fapi_auth_request_method|TEST_PLAN|
|-------------------|---------|----------------|------------|------------------|------------------------|---------|
|FAPI Adv. OP w/ Private Key|fapi1-advanced-final-test-plan|private_key_jwt|plain_fapi|plain_response|by_value|--fapi1-advanced|
|FAPI Adv. OP w/ MTLS|fapi1-advanced-final-test-plan|mtls|plain_fapi|plain_response|by_value|--fapi1-advanced|
|FAPI Adv. OP w/ Private Key, PAR|fapi1-advanced-final-test-plan|private_key_jwt|plain_fapi|plain_response|pushed|--fapi1-advanced-par|
|FAPI Adv. OP w/ MTLS, PAR|fapi1-advanced-final-test-plan|mtls|plain_fapi|plain_response|pushed|--fapi1-advanced-par|
|FAPI Adv. OP w/ Private Key, JARM|fapi1-advanced-final-test-plan|private_key_jwt|plain_fapi|jarm|by_value|--fapi1-advanced-jarm|
|FAPI Adv. OP w/ MTLS, JARM|fapi1-advanced-final-test-plan|mtls|plain_fapi|jarm|by_value|--fapi1-advanced-jarm|
|FAPI Adv. OP w/ Private Key, PAR, JARM|fapi1-advanced-final-test-plan|private_key_jwt|plain_fapi|jarm|pushed|--fapi1-advanced-par-jarm|
|FAPI Adv. OP w/ MTLS, PAR, JARM|fapi1-advanced-final-test-plan|mtls|plain_fapi|jarm|pushed|--fapi1-advanced-par-jarm|

Note: If you run this tests, please use `realm-fapi1-advanced.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi1-advanced.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

**Certified Financial-grade API Client Initiated Backchannel Authentication Profile (FAPI-CIBA) OpenID Providers**

|Conformance Profile|Test Plan|client_auth_type|fapi_profile|ciba_mode|client_registration|TEST_PLAN|
|-------------------|---------|----------------|------------|---------|-------------------|---------|
|FAPI-CIBA OP poll w/ Private Key|fapi-ciba-id1-test-plan|private_key_jwt|plain_fapi|poll|static_client|--fapi-ciba-poll-id1|
|FAPI-CIBA OP poll w/ MTLS|fapi-ciba-id1-test-plan|mtls|plain_fapi|poll|static_client|--fapi-ciba-poll-id1|
|FAPI-CIBA OP ping w/ Private Key|fapi-ciba-id1-test-plan|private_key_jwt|plain_fapi|ping|static_client|--fapi-ciba-ping-id1|
|FAPI-CIBA OP ping w/ MTLS|fapi-ciba-id1-test-plan|mtls|plain_fapi|ping|static_client|--fapi-ciba-ping-id1|

Note: If you run this tests, please use `realm-fapi-ciba.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi-ciba.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

**Brazil Open Banking (Based on FAPI 1 Advanced Final)**

|Conformance Profile|Test Plan|client_auth_type|fapi_profile|fapi_response_mode|fapi_auth_request_method|TEST_PLAN|
|-------------------|---------|----------------|------------|------------------|------------------------|---------|
|BR-OB Adv. OP w/ Private Key|fapi1-advanced-final-test-plan|private_key_jwt|openbanking_brazil|plain_response|by_value|--ob-br-fapi1-advanced|
|BR-OB Adv. OP w/ MTLS|fapi1-advanced-final-test-plan|mtls|openbanking_brazil|plain_response|by_value|--ob-br-fapi1-advanced|
|BR-OB Adv. OP w/ Private Key, PAR|fapi1-advanced-final-test-plan|private_key_jwt|openbanking_brazil|plain_response|pushed|--ob-br-fapi1-advanced-par|
|BR-OB Adv. OP w/ MTLS, PAR|fapi1-advanced-final-test-plan|mtls|openbanking_brazil|plain_response|pushed|--ob-br-fapi1-advanced-par|
|BR-OB Adv. OP w/ Private Key, JARM|fapi1-advanced-final-test-plan|private_key_jwt|openbanking_brazil|jarm|by_value|--ob-br-fapi1-advanced-jarm|
|BR-OB Adv. OP w/ MTLS, JARM|fapi1-advanced-final-test-plan|mtls|openbanking_brazil|jarm|by_value|--ob-br-fapi1-advanced-jarm|
|BR-OB Adv. OP w/ Private Key, PAR, JARM|fapi1-advanced-final-test-plan|private_key_jwt|openbanking_brazil|jarm|pushed|--ob-br-fapi1-advanced-par-jarm|
|BR-OB Adv. OP w/ MTLS, PAR, JARM|fapi1-advanced-final-test-plan|mtls|openbanking_brazil|jarm|pushed|--ob-br-fapi1-advanced-par-jarm|

Note: If you run this tests, please use `realm-ob-br-fapi1-advanced.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-ob-br-fapi1-advanced.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

Note: Open Banking Brazil was evolved into Open Finance Brazil. Conformance tests of Open Banking Brazil were no longer supported since conformance suite version 5.1.11. Conformance tests of Open Finance Brazil is provided since conformance suite version 5.1.15.

**Brazil Open Finance (Based on FAPI 1 Advanced Final)**

|Conformance Profile|Test Plan|client_auth_type|fapi_profile|fapi_response_mode|fapi_auth_request_method|TEST_PLAN|
|-------------------|---------|----------------|------------|------------------|------------------------|---------|
|BR-OF Adv. OP w/ Private Key, PAR (FAPI-BR v2)|fapi1-advanced-final-test-plan|private_key_jwt|openbanking_brazil|plain_response|pushed|--of-br-fapi1-advanced|

Note: If you run this tests, please use `realm-of-br-fapi1-advanced.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-of-br-fapi1-advanced.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

**Australia CDR (Based on FAPI 1 Advanced Final)**

|Conformance Profile|Test Plan|client_auth_type|fapi_profile|fapi_response_mode|fapi_auth_request_method|TEST_PLAN|
|-------------------|---------|----------------|------------|------------------|------------------------|---------|
|AU-CDR Adv. OP w/ Private Key|fapi1-advanced-final-test-plan|private_key_jwt|consumerdataright_au|plain_response|by_value|--fapi-aus-cdr|
|AU-CDR Adv. OP w/ Private Key, PAR|fapi1-advanced-final-test-plan|private_key_jwt|consumerdataright_au|plain_response|pushed|--fapi-aus-cdr-par|
|AU-CDR Adv. OP w/ Private Key, PAR, JARM|fapi1-advanced-final-test-plan|private_key_jwt|consumerdataright_au|jarm|pushed|--fapi-aus-cdr-par-jarm|

Note: If you run this tests, please use `realm-fapi-aus-cdr.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi-aus-cdr.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```
According to [Australia CDR security profile specification](https://consumerdatastandardsaustralia.github.io/standards/#authentication-flows), From May 12th 2025, JARM is mandatory, and tt seems that the conformance suite from v5.1.33 only accepts the "AU-CDR Adv. OP w/ Private Key, PAR, JARM" conformance profile while the current Conformance Test Execution Platform can run the "AU-CDR Adv. OP w/ Private Key" and "AU-CDR Adv. OP w/ Private Key, PAR" conformance profile tests. Therfore, from the conformance suite version v5.1.33, it only tests "AU-CDR Adv. OP w/ Private Key, PAR, JARM" conformance profile.

**UK Open Banking (Based on FAPI 1 Advanced Final)**

|Conformance Profile|Test Plan|client_auth_type|fapi_profile|fapi_response_mode|fapi_auth_request_method|TEST_PLAN|
|-------------------|---------|----------------|------------|------------------|------------------------|---------|
|UK-OB Adv. OP w/ MTLS|fapi1-advanced-final-test-plan|mtls|openbanking_uk|plain_response|by_value|--fapi-aus-cdr|
|UK-OB Adv. OP w/ Private Key|fapi1-advanced-final-test-plan|private_key_jwt|openbanking_uk|plain_response|by_value|--fapi-aus-cdr-par|

Note: If you run this tests, please use `realm-fapi-uk-ob.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi-uk-ob.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

**OpenID Connect OpenID Providers**

|Conformance Profile|Test Plan|server_metadata|client_registration|response_type|TEST_PLAN|
|-------------------|---------|---------------|-------------------|-------------|---------|
|Config OP|oidcc-config-certification-test-plan|-|-|-|--oidc-config|
|Basic OP|oidcc-basic-certification-test-plan|discovery|static_client|-|--oidc-basic|
|Basic OP|oidcc-basic-certification-test-plan|discovery|dynamic_client|-|--oidc-basic|
|Basic OP|oidcc-basic-certification-test-plan|static|static_client|-|--oidc-basic|
|Implicit OP|oidcc-implicit-certification-test-plan|discovery|static_client|-|--oidc-implicit|
|Implicit OP|oidcc-implicit-certification-test-plan|discovery|dynamic_client|-|--oidc-implicit|
|Implicit OP|oidcc-implicit-certification-test-plan|static|static_client|-|--oidc-implicit|
|Hybrid OP|oidcc-hybrid-certification-test-plan|discovery|static_client|-|--oidc-hybrid|
|Hybrid OP|oidcc-hybrid-certification-test-plan|discovery|dynamic_client|-|--oidc-hybrid|
|Hybrid OP|oidcc-hybrid-certification-test-plan|static|static_client|-|--oidc-hybrid|
|Form Post OP|oidcc-basic-certification-test-plan|discovery|static_client|-|--oidc-formpost|
|Form Post OP|oidcc-basic-certification-test-plan|discovery|dynamic_client|-|--oidc-formpost|
|Form Post OP|oidcc-basic-certification-test-plan|static|static_client|-|--oidc-formpost|
|Form Post OP|oidcc-implicit-certification-test-plan|discovery|static_client|-|--oidc-formpost|
|Form Post OP|oidcc-implicit-certification-test-plan|discovery|dynamic_client|-|--oidc-formpost|
|Form Post OP|oidcc-implicit-certification-test-plan|static|static_client|-|--oidc-formpost|
|Form Post OP|oidcc-hybrid-certification-test-plan|discovery|static_client|-|--oidc-formpost|
|Form Post OP|oidcc-hybrid-certification-test-plan|discovery|dynamic_client|-|--oidc-formpost|
|Form Post OP|oidcc-hybrid-certification-test-plan|static|static_client|-|--oidc-formpost|
|Dynamic OP|oidcc-dynamic-certification-test-plan|-|-|code idtoken|--oidc-dynamic|
|Dynamic OP|oidcc-dynamic-certification-test-plan|-|-|code id_token token|--oidc-dynamic|
|Dynamic OP|oidcc-dynamic-certification-test-plan|-|-|code|--oidc-dynamic|
|Dynamic OP|oidcc-dynamic-certification-test-plan|-|-|idtoken|--oidc-dynamic|
|Dynamic OP|oidcc-dynamic-certification-test-plan|-|-|id_token token|--oidc-dynamic|
|Dynamic OP|oidcc-dynamic-certification-test-plan|-|-|code token|--oidc-dynamic|
|3rd Party-Init OP|oidcc-3rdparty-init-login-certification-test-plan|-|-|code idtoken|--oidc-3rdparty-init-login|

Note: If you run this tests, please use `realm-oidc.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-oidc.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

**OpenID Connect OpenID Providers for Logout Profile**

|Conformance Profile|Test Plan|client_registration|response_type|TEST_PLAN|
|-------------------|---------|-------------------|-------------|---------|
|Front-Channel OP|oidcc-frontchannel-rp-initiated-logout-certification-test-plan|static_client|code idtoken|--oidc-frontchanel-rp-initiated-logout|
|Front-Channel OP|oidcc-frontchannel-rp-initiated-logout-certification-test-plan|static_client|code id_token token|--oidc-frontchanel-rp-initiated-logout|
|Front-Channel OP|oidcc-frontchannel-rp-initiated-logout-certification-test-plan|static_client|code|--oidc-frontchanel-rp-initiated-logout|
|Front-Channel OP|oidcc-frontchannel-rp-initiated-logout-certification-test-plan|static_client|idtoken|--oidc-frontchanel-rp-initiated-logout|
|Front-Channel OP|oidcc-frontchannel-rp-initiated-logout-certification-test-plan|static_client|id_token token|--oidc-frontchanel-rp-initiated-logout|
|Front-Channel OP|oidcc-frontchannel-rp-initiated-logout-certification-test-plan|static_client|code token|--oidc-frontchanel-rp-initiated-logout|
|Back-Channel OP|oidcc-backchannel-rp-initiated-logout-certification-test-plan|static_client|code idtoken|--oidc-backchannel-rp-initiated-logout|
|Back-Channel OP|oidcc-backchannel-rp-initiated-logout-certification-test-plan|static_client|code id_token token|--oidc-backchannel-rp-initiated-logout|
|Back-Channel OP|oidcc-backchannelchannel-rp-initiated-logout-certification-test-plan|static_client|code|--oidc-backchannel-rp-initiated-logout|
|Back-Channel OP|oidcc-backchannel-rp-initiated-logout-certification-test-plan|static_client|idtoken|--oidc-backchannel-rp-initiated-logout|
|Back-Channel OP|oidcc-backchannel-rp-initiated-logout-certification-test-plan|static_client|id_token token|--oidc-backchannel-rp-initiated-logout|
|Back-Channel OP|oidcc-backchannel-rp-initiated-logout-certification-test-plan|static_client|code token|--oidc-backchannel-rp-initiated-logout|
|Session OP|oidcc-session-management-certification-test-plan|static_client|code idtoken|--oidc-session-management|
|Session OP|oidcc-session-management-certification-test-plan|static_client|code id_token token|--oidc-session-management|
|Session OP|oidcc-session-management-certification-test-plan|static_client|code|--oidc-session-management|
|Session OP|oidcc-session-management-certification-test-plan|static_client|idtoken|--oidc-session-management|
|Session OP|oidcc-session-management-certification-test-plan|static_client|id_token token|--oidc-session-management|
|Session OP|oidcc-session-management-certification-test-plan|static_client|code token|--oidc-session-management|
|RP-Initiated OP|oidcc-rp-initiated-logout-certification-test-plan|static_client|code idtoken|--oidc-rp-initiated-logout|
|RP-Initiated OP|oidcc-rp-initiated-logout-certification-test-plan|static_client|code id_token token|--oidc-rp-initiated-logout|
|RP-Initiated OP|oidcc-rp-initiated-logout-certification-test-plan|static_client|code|--oidc-rp-initiated-logout|
|RP-Initiated OP|oidcc-rp-initiated-logout-certification-test-plan|static_client|idtoken|--oidc-rp-initiated-logout|
|RP-Initiated OP|oidcc-rp-initiated-logout-certification-test-plan|static_client|id_token token|--oidc-rp-initiated-logout|
|RP-Initiated OP|oidcc-rp-initiated-logout-certification-test-plan|static_client|code token|--oidc-rp-initiated-logout|

Note: If you run this tests, please use `realm-oidc-logout.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-oidc-logout.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

Note: Session OP and Front-Channel OP of OpenID Provider for Logout Profile conformance tests cannot be automated. These can be passed manually.

**FAPI 2.0 Security Profile Second Implementer’s Draft**

|Conformance Profile|Test Plan|sender_constrain|client_auth_type|authorization_request_type|openid|fapi_profile|TEST_PLAN|
|-|-|-|-|-|-|-|-|
|FAPI2SP MTLS + MTLS|fapi2-security-profile-id2-test-plan|mtls|mtls|simple|plain_oauth|plain_fapi|--fapi2-sp-id2-all|
|FAPI2SP private key + MTLS|fapi2-security-profile-id2-test-plan|mtls|private_key_jwt|simple|plain_oauth|plain_fapi|--fapi2-sp-id2-all|
|FAPI2SP OpenID Connect|fapi2-security-profile-id2-test-plan|mtls|mtls|simple|openid_connect|plain_fapi|--fapi2-sp-id2-all|
|FAPI2SP MTLS + DPoP|fapi2-security-profile-id2-test-plan|dpop|mtls|simple|plain_oauth|plain_fapi|--fapi2-sp-id2-all|
|FAPI2SP private key + DPoP|fapi2-security-profile-id2-test-plan|dpop|private_key_jwt|simple|plain_oauth|plain_fapi|--fapi2-sp-id2-all|
|FAPI2SP OpenID Connect + DPoP|fapi2-security-profile-id2-test-plan|dpop|mtls|simple|openid_connect|plain_fapi|--fapi2-sp-id2-all|

Note: If you run this tests, please use `realm-fapi2-sp-id2.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi2-sp-id2.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

**FAPI 2.0 Message Signing First Implementer’s Draft**

|Conformance Profile|Test Plan|sender_constrain|client_auth_type|authorization_request_type|openid|fapi_request_method|fapi_profile|fapi_response_mode|TEST_PLAN|
|-|-|-|-|-|-|-|-|-|-|
|FAPI2MS JAR|fapi2-message-signing-id1-test-plan|mtls|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|plain_response|--fapi2-ms-id1-all|
|FAPI2MS JARM|fapi2-message-signing-id1-test-plan|mtls|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|jarm|--fapi2-ms-id1-all|
|FAPI2MS JAR + DPoP|fapi2-message-signing-id1-test-plan|dpop|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|plain_response|--fapi2-ms-id1-all|
|FAPI2MS JARM + DPoP|fapi2-message-signing-id1-test-plan|dpop|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|jarm|--fapi2-ms-id1-all|

Note: If you run this conformance tests, please use `realm-fapi2-ms-id1.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi2-ms-id1.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

**FAPI 2.0 Security Profile Final**

|Conformance Profile|Test Plan|sender_constrain|client_auth_type|authorization_request_type|openid|fapi_profile|TEST_PLAN|
|-|-|-|-|-|-|-|-|
|FAPI2SP MTLS + MTLS|fapi2-security-profile-final-test-plan|mtls|mtls|simple|plain_oauth|plain_fapi|--fapi2-sp-final-all|
|FAPI2SP private key + MTLS|fapi2-security-profile-final-test-plan|mtls|private_key_jwt|simple|plain_oauth|plain_fapi|--fapi2-sp-final-all|
|FAPI2SP OpenID Connect|fapi2-security-profile-final-test-plan|mtls|mtls|simple|openid_connect|plain_fapi|--fapi2-sp-final-all|
|FAPI2SP MTLS + DPoP|fapi2-security-profile-final-test-plan|dpop|mtls|simple|plain_oauth|plain_fapi|--fapi2-sp-final-all|
|FAPI2SP private key + DPoP|fapi2-security-profile-final-test-plan|dpop|private_key_jwt|simple|plain_oauth|plain_fapi|--fapi2-sp-final-all|
|FAPI2SP OpenID Connect + DPoP|fapi2-security-profile-final-test-plan|dpop|mtls|simple|openid_connect|plain_fapi|--fapi2-sp-final-all|

Note: If you run this tests, please use `realm-fapi2-sp-final.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi2-sp-final.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

Note: If you run this tests, please comment out the following line in `keycloak-custom.properties` file like:
```
#spi-login-protocol-openid-connect-allow-multiple-audiences-for-jwt-client-authentication=true
```

**FAPI 2.0 Message Signing Final**

|Conformance Profile|Test Plan|sender_constrain|client_auth_type|authorization_request_type|openid|fapi_request_method|fapi_profile|fapi_response_mode|TEST_PLAN|
|-|-|-|-|-|-|-|-|-|-|
|FAPI2MS JAR|fapi2-message-signing-final-test-plan|mtls|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|plain_response|--fapi2-ms-final-all|
|FAPI2MS JARM|fapi2-message-signing-final-test-plan|mtls|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|jarm|--fapi2-ms-final-all|
|FAPI2MS JAR + DPoP|fapi2-message-signing-final-test-plan|dpop|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|plain_response|--fapi2-ms-final-all|
|FAPI2MS JARM + DPoP|fapi2-message-signing-final-test-plan|dpop|mtls|simple|plain_oauth|signed_non_repudiation|plain_fapi|jarm|--fapi2-ms-final-all|

Note: If you run this conformance tests, please use `realm-fapi2-ms-final.json` realm setting file like:
```
KEYCLOAK_REALM_IMPORT_FILENAME=realm-fapi2-ms-final.json docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

Eg. The following command runs `FAPI Adv. OP w/ Private Key, PAR, JARM` and `FAPI Adv. OP w/ MTLS, PAR, JARM` conformance test.
```
TEST_PLAN=--fapi1-advanced-par-jarm docker-compose -p keycloak-fapi -f docker-compose.yml up --build
```

If you set `--server-tests-only` to `TEST_PLAN`, it runs all types of FAPI conformance tests shown above the table automatically.

If you set `--fapi1-advanced-all` to `TEST_PLAN`, it runs all types of FAPI 1 Advanced Final (Generic) conformance tests shown above the table automatically.

If you set `--fapi-ciba-all` to `TEST_PLAN`, it runs all types of FAPI-CIBA OpenID Providers conformance tests shown above the table automatically.

If you set `--ob-br-fapi1-advanced-all` to `TEST_PLAN`, it runs all types of Brazil Open Banking (Based on FAPI 1 Advanced Final) conformance tests shown above the table automatically.

If you set `--of-br-fapi1-advanced-all` to `TEST_PLAN`, it runs all types of Brazil Open Finance (Based on FAPI 1 Advanced Final) conformance tests shown above the table automatically.

If you set `--fapi-aus-cdr-all` to `TEST_PLAN`, it runs all types of Australia CDR (Based on FAPI 1 Advanced Final) conformance tests shown above the table automatically.

If you set `--fapi-uk-ob-all` to `TEST_PLAN`, it runs all types of UK Open Banking (Based on FAPI 1 Advanced Final) conformance tests shown above the table automatically.

If you set `--oidc-all` to `TEST_PLAN`, it runs all types of OpenID Provider conformance tests shown above the table automatically.

If you set `--oidc-logout-all` to `TEST_PLAN`, it runs all types of OpenID Provider for Logout Profile conformance tests shown above the table automatically except for Session OP and Front-Channel OP.

If you set `--fapi2-sp-id2-all` to `TEST_PLAN`, it runs all types of FAPI 2.0 Security Profile Second Implementer’s Draft conformance tests shown above the table automatically.

If you set `--fapi2-ms-id1-all` to `TEST_PLAN`, it runs all types of FAPI 2.0 Message Signing First Implementer’s Draft conformance tests shown above the table automatically.

If you set `--fapi2-sp-final-all` to `TEST_PLAN`, it runs all types of FAPI 2.0 Security Profile Final conformance tests shown above the table automatically.

If you set `--fapi2-ms-final-all` to `TEST_PLAN`, it runs all types of FAPI 2.0 Message Final conformance tests shown above the table automatically.

If you set nothing to `TEST_PLAN`, it runs FAPI conformance tests the same as set `--fapi1-advanced-all`.

Note: Open Banking Brazil was evolved into Open Finance Brazil. Conformance tests of Open Banking Brazil were no longer supported since conformance suite version 5.1.11. Conformance tests of Open Finance Brazil is provided since conformance suite version 5.1.15.

### Notes

#### Overlay with locally installed keycloak

On building container image of keycloak, CIBA settings are applied to keycloak (standalone-ha.xml). It means that these CIBA settings do not work when using locally build keycloak because these CIBA settings are applied to containerized keycloak, not locally installed keycloak.

To get around this issue, modules and themes of containerized keycloak are overlaid with ones of locally built keycloak by modifying docker-compose.yml as follows.

```
@@ -28,6 +28,7 @@ services:
      - ./common/https/server.pem:/etc/x509/https/tls.crt
      - ./common/https/server-key.pem:/etc/x509/https/tls.key
      - ./common/https/client-ca.pem:/etc/x509/https/client-ca.crt
+     - <top directory path to locally built keycloak>/modules:/opt/keycloak/modules
+     - <top directory path to locally built keycloak>/modules:/opt/keycloak/themes:/opt/keycloak/themes
     ports:
      - "8787:8787"
     environment:
```

#### Not passed tests automatically

Due to the nature of conformance suite, the following tests cannot be passed automatically. After completion of automatic tests, you can run them manually and confirm they are passed.

##### PAR attempt with request_uri reuse

  * fapi1-advanced-final-par-attempt-reuse-request_uri
  * fapi2-advanced-id2-par-attempt-reuse-request_uri
  * fapi2-advanced-final-par-attempt-reuse-request_uri

##### Server Signing Key Rotation

  * oidcc-server-rotate-keys

 This always become `failure` status in automated tests. However, we can pass this test manually by createing a new key in sigature and disabling the exsiting key (RS256) in signature on an admin console.

##### FAPI2 Final PAR request reuse check with multiple authorization flow in parallel

  * fapi2-security-profile-final-par-ensure-reused-request-uri-prior-to-auth-completion-succeeds

The following actions need to be taken manually:
  - When the "Proceed with test" button is shown firstly, push it to open the Keycloak's login page as a new tab, but do nothing.
  - Consecutively, when the "Proceed with test" button is shown secondly, push it, which shows an error page as a new tab.
  - Take the snapshot of the error page, and upload it to the conformance suite server.

As this test description shows, it tests [FAPI 2.0 Security Profile 5.3.2.2](https://openid.net/specs/fapi-security-profile-2_0-final.html#name-notational-conventions) Note 3. It is "recommended" item so that this error page is treated as "warning".

**Running different test plans**

To create custom test plans, add code into /conformance-suite/run-tests.sh as per commented out examples.
JSON configuration files for test plans should be created in /conformance-suite/.gitlab-ci/

## License

* [Apache License, Version 2.0](./LICENSE)

