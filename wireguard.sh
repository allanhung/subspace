#!/usr/bin/env sh
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

#
# WireGuard (Load module)
#
rm -rf /usr/src/kernels/*
ln -sf /host/usr/src/kernels/$(uname -r) /usr/src/kernels/
WG_VERSION=$(dkms status |grep wireguard | awk -F':' '{print $1}' | awk -F'/' '{print $2}' | awk -F',' '{print $1}')
dkms build -m wireguard -v ${WG_VERSION}
dkms install -m wireguard -v ${WG_VERSION}
#
# WireGuard (Bring up interface)
#
wg-quidk up wg0

exec $@
