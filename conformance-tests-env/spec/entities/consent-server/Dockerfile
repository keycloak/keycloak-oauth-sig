FROM golang:1.16.5-alpine3.14 AS builder

ENV GO111MODULE=on

WORKDIR /go/src/github.com/soss-sig/keycloak-fapi
COPY *.go ./

RUN go mod init
RUN go get github.com/google/uuid
RUN go build -o consent-server *.go

FROM alpine:3.14

# Install consent-server for testing
COPY --from=builder /go/src/github.com/soss-sig/keycloak-fapi/consent-server /usr/local/sbin/

ENTRYPOINT [ "consent-server" ]

