# Gluetun

Runs [Gluetun](https://github.com/qdm12/gluetun), a VPN client for many providers,
and exposes its **HTTP proxy** (and optionally its **Shadowsocks** server) on your
network. Devices or apps configured to use the proxy go out through the VPN; the
rest of Home Assistant is not affected.

Gluetun runs in its own network namespace with its kill switch: if the VPN goes
down, traffic through the proxy is blocked instead of leaking.

## Configuration

1. Set **VPN service provider** (for example `mullvad`, `protonvpn`, `nordvpn`)
   and **VPN type**.
2. Fill in the credentials for that type:
   - WireGuard: **WireGuard private key** and **WireGuard addresses**
     (plus **preshared key** if your provider uses one).
   - OpenVPN: **OpenVPN user** and **OpenVPN password**.
3. Optionally narrow the server choice with **Server countries**, **cities** or
   **hostnames**.
4. Set an **HTTP proxy user** and **password**: without them, anyone on your
   network can use the proxy.
5. Start the app and check the log for the public IP Gluetun reports.

Each provider needs slightly different settings: check its page in the
[Gluetun wiki](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers).

### Extra environment variables

Any Gluetun variable not covered by the options can be set in
**Extra environment variables**, as `name` / `value` pairs. They are applied last
and override the options above. For example, for a custom WireGuard server:

```yaml
vpn_service_provider: custom
vpn_type: wireguard
wireguard_private_key: "..."
wireguard_addresses: 10.2.0.2/32
env:
  - name: WIREGUARD_ENDPOINT_IP
    value: 203.0.113.10
  - name: WIREGUARD_ENDPOINT_PORT
    value: "51820"
  - name: WIREGUARD_PUBLIC_KEY
    value: "..."
```

### Files

The app config folder is mounted at `/config` (on the host:
`/app_configs/<repository>_gluetun`). Put files there and point Gluetun to them,
for example a custom OpenVPN config with `OPENVPN_CUSTOM_CONFIG=/config/vpn.ovpn`
or a WireGuard config with `WIREGUARD_CONF_SECRETFILE=/config/wg0.conf`.

## Ports

| Port | Use | Default |
|---|---|---|
| 80/tcp | SNI proxy, HTTP | enabled |
| 443/tcp | SNI proxy, HTTPS | enabled |
| 8888/tcp | HTTP proxy | disabled: enable the 8888 port to use it |
| 8388/tcp + udp | Shadowsocks | disabled: enable the **Shadowsocks** option and these ports |
| 8000/tcp | Gluetun control server | disabled: needs an auth config, see the Gluetun wiki |

## Using the SNI proxy

Once the VPN is up, nginx listens on ports 443 and 80 and forwards each
connection to the host it asks for (the TLS SNI name on 443, the `Host` header
on 80), through the VPN. TLS is not decrypted. Point the DNS names you want to
route through the VPN (for example with a DNS rewrite in AdGuard Home or
Pi-hole) to your Home Assistant IP: devices then reach those sites through the
VPN without any proxy setting.

Ports 80 and 443 must be free on the host: if another app already uses them,
this app will not start.

## Using the HTTP proxy

Enable the 8888 port in the Network section, then point a device or app to `http://<home-assistant-ip>:8888` (with the proxy
credentials if set). Other apps can reach it on the internal network at
`http://<app-hostname>:8888`.
