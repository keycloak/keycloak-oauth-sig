FROM golang:1.22-alpine3.19 AS builder

ENV GO111MODULE=on
WORKDIR /go/src/github.com/soss-sig/keycloak-fapi
COPY *.go ./
RUN go build -o client-jwks-server *.go


FROM alpine:3.19

# Install client-jwks-server for testing
COPY --from=builder /go/src/github.com/soss-sig/keycloak-fapi/client-jwks-server /usr/local/sbin/
ADD . /keys
ENTRYPOINT [ "client-jwks-server" ]

