# Dockerfile - alpine-fat
# https://github.com/openresty/docker-openresty
#
# This is an alpine-based build that keeps some build-related
# packages, has perl installed for opm, and includes luarocks.

FROM alpine:latest

MAINTAINER Evan Wies <evan@neomantra.net>

# Docker Build Arguments
ARG RESTY_VERSION="1.11.2.4"
ARG RESTY_LUAROCKS_VERSION="2.4.2"
ARG RESTY_OPENSSL_VERSION="1.0.2k"
ARG RESTY_LUA_CJSON="2.1.0.5"
ARG RESTY_PCRE_VERSION="8.39"
ARG RESTY_J="4"
ARG SPNEGO_HTTP_AUTH_VERSION="1.1.0"
ARG RESTY_CONFIG_OPTIONS="\
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    --add-module=spnego-http-auth-nginx-module \
    "

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION}"


# 1) Install apk dependencies
# 2) Download and untar OpenSSL, PCRE, and OpenResty
# 3) Build OpenResty
# 4) Cleanup

RUN \
    apk add --no-cache --virtual .build-deps \
        curl \
        gd-dev \
        geoip-dev \
        krb5-dev \
        libxslt-dev \
        perl-dev \
        readline-dev \
        zlib-dev \
    && apk add --no-cache \
        build-base \
        curl \
        gd \
        geoip \
        krb5-libs \
        libgcc \
        libxslt \
        linux-headers \
        make \
        perl \
        unzip \
        zlib \
    && cd /tmp \
    && curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && curl -fSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && curl -fSL https://github.com/stnoonan/spnego-http-auth-nginx-module/archive/v${SPNEGO_HTTP_AUTH_VERSION}.tar.gz -o spnego-http-auth-nginx-module-${SPNEGO_HTTP_AUTH_VERSION}.tar.gz \
    && tar xzf spnego-http-auth-nginx-module-${SPNEGO_HTTP_AUTH_VERSION}.tar.gz \
    && mv spnego-http-auth-nginx-module-${SPNEGO_HTTP_AUTH_VERSION} spnego-http-auth-nginx-module \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && curl -fSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta2 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp/openresty-${RESTY_VERSION}/build/lua-cjson-${RESTY_LUA_CJSON} \
    && /usr/local/openresty/luajit/bin/luarocks make \
    && cd /tmp \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION} \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && apk del .build-deps \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin/:/usr/local/openresty/nginx/sbin/:/usr/local/openresty/bin/

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

