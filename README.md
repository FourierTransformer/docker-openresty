Current Version: 1.11.2.5

This is an alpine-fat only fork of the openresty [docker container](https://github.com/openresty/docker-openresty) with the following additional changes:
  * lua-cjson is made available via LuaRocks (so you can install things that rely on it, avoiding [this bug](https://github.com/openresty/docker-openresty/issues/35))
  * [spnego-http-auth-nginx-module](https://github.com/stnoonan/spnego-http-auth-nginx-module) has been added for spnego support

Note: I will try to keep this up to date with the official repo.
