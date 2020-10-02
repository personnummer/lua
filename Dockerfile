FROM alpine:latest
WORKDIR /app

ENV LUA_VERSION 5.3
ENV LUA_PACKAGE lua${LUA_VERSION}

RUN apk --no-cache add ${LUA_PACKAGE} ${LUA_PACKAGE}-dev build-base git bash unzip curl outils-md5 \
    && cd /tmp \
    && git clone https://github.com/keplerproject/luarocks.git \
    && cd luarocks \
    && sh ./configure \
    && make build install \
    && cd \
    && rm -rf /tmp/luarocks

RUN luarocks install busted