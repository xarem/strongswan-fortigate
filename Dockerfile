# Debian's strongSwan packages with the FortiGate patches from patches/.
# The image only holds the packages, in /debs.
FROM debian:trixie AS build

RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends dpkg-dev fakeroot \
 && apt-get build-dep -y strongswan

WORKDIR /build
RUN apt-get source strongswan

COPY patches/ /patches/
RUN cd strongswan-*/ \
 && for p in /patches/*.patch; do patch -p1 <"$p"; done \
 && version=$(dpkg-parsechangelog -S Version) \
 && { printf 'strongswan (%s+fortigate1) trixie; urgency=medium\n\n  * FortiGate compatibility patches.\n\n -- strongswan-fortigate <strongswan-fortigate@users.noreply.github.com>  %s\n\n' \
        "$version" "$(date -R)"; cat debian/changelog; } >debian/changelog.new \
 && mv debian/changelog.new debian/changelog \
 && DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" dpkg-buildpackage -B -uc -us \
 && mkdir /debs && cp ../*.deb /debs/ && rm /debs/*-dbgsym_*.deb

FROM scratch
LABEL org.opencontainers.image.source=https://github.com/xarem/strongswan-fortigate
COPY --from=build /debs/ /debs/
