FROM golang:1.22-alpine3.19 AS builder

ENV GO111MODULE=on
WORKDIR /go/src/github.com/soss-sig/keycloak-fapi
COPY *.go ./
RUN go build -o auth_entity_server *.go


FROM alpine:3.19

# Install resource-server for testing
COPY --from=builder /go/src/github.com/soss-sig/keycloak-fapi/auth_entity_server /usr/local/sbin/

ENTRYPOINT [ "auth_entity_server" ]

