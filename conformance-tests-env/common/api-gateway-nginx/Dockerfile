FROM openresty/openresty:alpine-fat

RUN apk update && apk add ca-certificates

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-openidc \
  && /usr/local/openresty/luajit/bin/luarocks install lua-resty-jit-uuid

COPY *.template /usr/local/openresty/nginx/conf/
COPY *.lua /usr/local/openresty/

COPY entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]
CMD []
