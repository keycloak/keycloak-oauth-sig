FROM maven:3.8.3-openjdk-17-slim AS builder
ARG OPENID_GIT_URL
ARG OPENID_GIT_TAG

RUN apt-get update && apt-get install -y git
RUN git clone -b ${OPENID_GIT_TAG} ${OPENID_GIT_URL} ./conformance-suite
ADD . ./conformance-suite/
RUN cd conformance-suite && mv -f run-tests.sh ./.gitlab-ci && mvn package -DskipTests

FROM eclipse-temurin:17

# the server app requires redir to run
RUN apt-get update && apt-get install -y redir python3 python3-pip curl \
    && pip3 install httpx pyparsing --break-system-packages \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /conformance-suite /conformance-suite
EXPOSE 8080
EXPOSE 9090
CMD [ "sh", "./conformance-suite/server-entrypoint.sh" ]
