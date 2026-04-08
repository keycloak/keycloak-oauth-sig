FROM golang:1.23.2-alpine3.20 AS builder

ENV GO111MODULE=on
WORKDIR /go/src/github.com/soss-sig/keycloak-fapi
RUN apk update && apk add git
COPY go.mod *.go ./
RUN go mod download github.com/lestrrat-go/jwx
RUN go mod tidy
RUN go build -o dpop-proof-signature-verify-server *.go


FROM alpine:3.9

# Install resource-server for testing
COPY --from=builder /go/src/github.com/soss-sig/keycloak-fapi/dpop-proof-signature-verify-server /usr/local/sbin/

ENTRYPOINT [ "dpop-proof-signature-verify-server" ]

