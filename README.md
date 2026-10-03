# strongswan-fortigate

Debian 13 (trixie) strongSwan packages patched to connect to FortiGate IKEv2
dial-up VPNs the way FortiClient does: PSK + EAP-MSCHAPv2, followed by a
FortiToken code via EAP-GTC.

The patches in `patches/` are taken unchanged from
[Noneawe/strongswan-deb-build](https://github.com/Noneawe/strongswan-deb-build),
see [strongswan#3120](https://github.com/strongswan/strongswan/issues/3120)
for the protocol details. They apply to Debian's strongSwan with line offsets
only.

## Image

`ghcr.io/xarem/strongswan-fortigate` holds the built packages in `/debs`,
for `linux/amd64` and `linux/arm64`. It is rebuilt weekly to pick up Debian
security updates.

```dockerfile
FROM ghcr.io/xarem/strongswan-fortigate:latest AS strongswan

FROM debian:trixie
RUN --mount=from=strongswan,source=/debs,target=/tmp/strongswan \
    apt-get update && apt-get install -y --no-install-recommends \
      /tmp/strongswan/libstrongswan_*.deb /tmp/strongswan/libstrongswan-standard-plugins_*.deb \
      /tmp/strongswan/strongswan-libcharon_*.deb /tmp/strongswan/strongswan-charon_*.deb \
      /tmp/strongswan/strongswan-starter_*.deb /tmp/strongswan/strongswan-swanctl_*.deb \
      /tmp/strongswan/libcharon-extauth-plugins_*.deb /tmp/strongswan/libcharon-extra-plugins_*.deb
```

## Configuration

The patches only change behaviour when enabled in `strongswan.conf`:

```
charon {
  fortigate_auth_key = skp
  fortigate_suppress_eap_only = yes
  fortigate_send_forticlient_vid = yes
  fortigate_fct_file = /path/to/forticlient-connect.txt
  plugins {
    eap-gtc {
      # prints the token code on stdout
      otp_helper = /path/to/otp-helper
      otp_mode = always
    }
  }
}
```

Connection: `local { auth = eap-mschapv2 }`, `remote { auth = psk }`, no
remote `id`. Example for the FCT file:
[fortivpn-nm/etc/fct_data.txt](https://github.com/Noneawe/fortivpn-nm/blob/main/etc/fct_data.txt).

Not covered: EAP-TTLS/PAP (FortiClient `eap_method` 2) and certificate
authentication with `eap-cert-auth`.

## Build locally

    docker build --output dist .
