FROM alpine:3.20
RUN apk add --no-cache openssl busybox-extras
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod a+x /entrypoint.sh
EXPOSE 8080
ENTRYPOINT [ "/entrypoint.sh" ]
