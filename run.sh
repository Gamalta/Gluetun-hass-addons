#!/bin/sh
# Translate the Home Assistant app options into Gluetun environment variables,
# then hand over to the original Gluetun entrypoint.
set -eu

OPTIONS=/data/options.json

log() {
    echo "[gluetun-app] $*"
}

# Print an option value: booleans become on/off, missing or null print nothing.
option() {
    jq -r --arg key "$1" '
        .[$key]
        | if . == null then empty
          elif type == "boolean" then (if . then "on" else "off" end)
          else tostring end
    ' "${OPTIONS}"
}

# map_option VARIABLE option_key
map_option() {
    value=$(option "$2")
    if [ -n "${value}" ]; then
        export "$1=${value}"
        log "Set $1 from option '$2'"
    fi
}

# Keep the downloaded server list across restarts.
export STORAGE_FILEPATH=/data/servers.json

map_option VPN_SERVICE_PROVIDER vpn_service_provider
map_option VPN_TYPE vpn_type
map_option OPENVPN_USER openvpn_user
map_option OPENVPN_PASSWORD openvpn_password
map_option WIREGUARD_PRIVATE_KEY wireguard_private_key
map_option WIREGUARD_PRESHARED_KEY wireguard_preshared_key
map_option WIREGUARD_ADDRESSES wireguard_addresses
map_option SERVER_COUNTRIES server_countries
map_option SERVER_CITIES server_cities
map_option SERVER_HOSTNAMES server_hostnames
map_option HTTPPROXY httpproxy
map_option HTTPPROXY_USER httpproxy_user
map_option HTTPPROXY_PASSWORD httpproxy_password
map_option SHADOWSOCKS shadowsocks
map_option SHADOWSOCKS_PASSWORD shadowsocks_password
map_option FIREWALL_OUTBOUND_SUBNETS firewall_outbound_subnets
map_option LOG_LEVEL log_level

# Any other Gluetun variable, from the 'env' list. Applied last so it can
# override the options above.
count=$(jq '.env // [] | length' "${OPTIONS}")
i=0
while [ "${i}" -lt "${count}" ]; do
    name=$(jq -r --argjson i "${i}" '.env[$i].name // ""' "${OPTIONS}")
    value=$(jq -r --argjson i "${i}" '.env[$i].value // ""' "${OPTIONS}")
    case "${name}" in
        "" | [0-9]* | *[!A-Za-z0-9_]*)
            log "Skipping invalid variable name '${name}'"
            ;;
        *)
            export "${name}=${value}"
            log "Set ${name} from 'env'"
            ;;
    esac
    i=$((i + 1))
done

# SNI proxy (nginx): let ports 80 and 443 through Gluetun's firewall, then
# start nginx in the background once the VPN interface is up.
export FIREWALL_INPUT_PORTS="${FIREWALL_INPUT_PORTS:+${FIREWALL_INPUT_PORTS},}80,443"

(
    until [ -d "/sys/class/net/${VPN_INTERFACE:-tun0}" ]; do sleep 2; done
    log "VPN up, starting SNI proxy"
    nginx
) &

log "Starting Gluetun..."
exec /gluetun-entrypoint "$@"
