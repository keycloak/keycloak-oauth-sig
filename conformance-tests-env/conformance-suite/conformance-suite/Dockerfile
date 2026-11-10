FROM maven:3.9-eclipse-temurin-21 AS builder
ARG OPENID_GIT_URL
ARG OPENID_GIT_TAG

RUN apt-get update && apt-get install -y git
RUN git clone -b ${OPENID_GIT_TAG} ${OPENID_GIT_URL} ./conformance-suite
ADD . ./conformance-suite/
# wait 1s past expires_in: the expired request_uri tests otherwise wait exactly the
# lifetime, and a backward clock correction during the wait makes them fail intermittently
RUN cd conformance-suite \
    && sed -i "s/return seconds;/return seconds + 1;/" src/main/java/net/openid/conformance/condition/client/WaitForExpiry.java \
    && grep -q "return seconds + 1;" src/main/java/net/openid/conformance/condition/client/WaitForExpiry.java
RUN cd conformance-suite && mv -f run-tests.sh ./.gitlab-ci && mvn package -DskipTests
# rotate OP signing keys just before run-test-plan.py starts oidcc-server-rotate-keys
RUN cd conformance-suite && sed -i 's/\r$//' rotate-op-keys.sh && chmod a+x rotate-op-keys.sh \
    && sed -i "s|^\(                    \)await conformance.start_test(module_id)$|\1if os.environ.get('ROTATE_OP_KEYS_COMMAND'): await asyncio.to_thread(subprocess.run, os.environ['ROTATE_OP_KEYS_COMMAND'], shell=True)\n&|" scripts/run-test-plan.py \
    && grep -q "ROTATE_OP_KEYS_COMMAND" scripts/run-test-plan.py
# drive Keycloak once a test module waits for it: OID4VCI issuer initiated credential offers and OID4VP verifier requests
RUN cd conformance-suite && sed -i 's/\r$//' oid4vc-interaction.py run-test-plan-waiting-hook.txt && chmod a+x oid4vc-interaction.py \
    && sed -i '/^            if state == "WAITING":$/r run-test-plan-waiting-hook.txt' scripts/run-test-plan.py \
    && grep -q "WAITING_INTERACTION_COMMAND" scripts/run-test-plan.py

FROM eclipse-temurin:21-jdk

# the server app requires redir to run
RUN apt-get update && apt-get install -y redir python3 python3-pip curl \
    && pip3 install httpx pyparsing --break-system-packages \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /conformance-suite /conformance-suite
EXPOSE 8080
EXPOSE 9090
CMD [ "sh", "./conformance-suite/server-entrypoint.sh" ]
