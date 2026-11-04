FROM maven:3.9-eclipse-temurin-21 AS builder
ARG OPENID_GIT_URL
ARG OPENID_GIT_TAG

RUN apt-get update && apt-get install -y git
RUN git clone -b ${OPENID_GIT_TAG} ${OPENID_GIT_URL} ./conformance-suite
ADD . ./conformance-suite/
RUN cd conformance-suite && mv -f run-tests.sh ./.gitlab-ci && mvn package -DskipTests
# rotate OP signing keys just before run-test-plan.py starts oidcc-server-rotate-keys
RUN cd conformance-suite && sed -i 's/\r$//' rotate-op-keys.sh && chmod a+x rotate-op-keys.sh \
    && sed -i "s|^\(                    \)await conformance.start_test(module_id)$|\1if os.environ.get('ROTATE_OP_KEYS_COMMAND'): await asyncio.to_thread(subprocess.run, os.environ['ROTATE_OP_KEYS_COMMAND'], shell=True)\n&|" scripts/run-test-plan.py \
    && grep -q "ROTATE_OP_KEYS_COMMAND" scripts/run-test-plan.py

FROM eclipse-temurin:21-jdk

# the server app requires redir to run
RUN apt-get update && apt-get install -y redir python3 python3-pip curl \
    && pip3 install httpx pyparsing --break-system-packages \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /conformance-suite /conformance-suite
EXPOSE 8080
EXPOSE 9090
CMD [ "sh", "./conformance-suite/server-entrypoint.sh" ]
