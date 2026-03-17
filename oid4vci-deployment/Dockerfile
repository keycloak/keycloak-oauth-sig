# ==========================================
# Stage 1: Build Stage
# ==========================================
FROM eclipse-temurin:21-jdk-jammy AS builder

# Set working directory
ENV WORK_DIR=/app
WORKDIR $WORK_DIR

# Install required dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends git apt-utils curl jq gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Install yq (required for configuration management via helper.sh)
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq

# Copy config file
COPY config.yaml ./

# Copy necessary source scripts
COPY src/deployment ./src/deployment
COPY src/utils ./src/utils

# Run setup to prepare Keycloak OID4VCI environment
RUN chmod +x src/deployment/setup-kc-oid4vci.sh && ./src/deployment/setup-kc-oid4vci.sh

# ==========================================
# Stage 2: Runtime Stage
# ==========================================
FROM eclipse-temurin:21-jdk-jammy

# Set working directory
WORKDIR /opt/keycloak

# Runtime dependencies required by helper scripts
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base jq && \
    rm -rf /var/lib/apt/lists/*

# Create a non-privileged user
RUN groupadd -r keycloak && useradd -r -g keycloak keycloak

# Copy the built Keycloak target from the build stage
COPY --from=builder /app/target /opt/keycloak/target

# Copy configuration files to runtime
COPY --from=builder /app/config.yaml /opt/keycloak/

# Copy helper utilities and yq so that runtime matches CLI behavior
COPY --from=builder /app/src/utils/helper.sh /opt/keycloak/src/utils/
COPY --from=builder /usr/bin/yq /usr/bin/yq

# Copy container entrypoint script
COPY docker-entrypoint.sh /opt/keycloak/docker-entrypoint.sh
RUN chmod +x /opt/keycloak/docker-entrypoint.sh

# Ensure proper permissions
RUN chown -R keycloak:keycloak /opt/keycloak

# Switch to non-privileged user
USER keycloak

# Expose Keycloak default ports
EXPOSE 8443

# Use custom entrypoint that initializes configuration via helper.sh
ENTRYPOINT ["/opt/keycloak/docker-entrypoint.sh"]
