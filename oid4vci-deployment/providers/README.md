# Keycloak providers

JAR files placed in this directory are mounted into the Keycloak instance:

- **Compose path**: mounted at `/opt/keycloak/providers` in the `app` service
  (see `docker-compose.yml`).
- **Tarball / `keycloak-ssi setup` path**: copied by `src/deployment/0.start-kc-oid4vci.sh`
  into the local Keycloak install's `providers` directory before startup.

Restart Keycloak after adding a provider JAR.

## Token Status plugin

To enable credential revocation (see `docs/revocable-credentials.md`), place the
[Keycloak Token Status plugin](https://github.com/ADORSYS-GIS/token-status-link)
JAR here. It is published to Maven Central. Example (pin the version you tested):

```bash
curl -fL -o providers/keycloak-token-status-plugin-0.5.2.jar \
  https://repo1.maven.org/maven2/io/github/adorsys-gis/keycloak-token-status-plugin/0.5.2/keycloak-token-status-plugin-0.5.2.jar
```

Set `status_list.plugin_version` in `config.yaml` to match the version you download.
