# Official Gluetun image (multi-arch). The base image is set here directly:
# since Supervisor 2026.04 build.yaml is legacy and BUILD_FROM is no longer provided.
FROM ghcr.io/qdm12/gluetun:v3.41.3

# jq is used by run.sh to read the app options.
# nginx (with its stream module) is the SNI / Host proxy on ports 443 and 80.
RUN apk add --no-cache jq nginx nginx-mod-stream

COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# run.sh turns /data/options.json into Gluetun environment variables,
# then execs the original /gluetun-entrypoint.
ENTRYPOINT ["/run.sh"]

# Build arguments (only BUILD_ARCH and BUILD_VERSION are provided by Supervisor)
ARG BUILD_ARCH
ARG BUILD_VERSION

LABEL \
    io.hass.name="Gluetun" \
    io.hass.description="VPN client exposing an HTTP proxy and a Shadowsocks server through your VPN provider" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="app" \
    io.hass.version=${BUILD_VERSION}
