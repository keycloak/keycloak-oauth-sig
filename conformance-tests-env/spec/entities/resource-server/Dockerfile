FROM golang:1.22-alpine3.19 AS builder

ENV GO111MODULE=on
WORKDIR /go/src/github.com/soss-sig/keycloak-fapi
COPY *.go ./
RUN go build -o resource-server *.go


FROM alpine:3.19

# Install resource-server for testing
COPY --from=builder /go/src/github.com/soss-sig/keycloak-fapi/resource-server /usr/local/sbin/

ENTRYPOINT [ "resource-server" ]

