#!/bin/sh
SOCKET_PATH="/tmp/tailscaled.sock"

tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --socket=$SOCKET_PATH --state=mem: &

while [ ! -S $SOCKET_PATH ]; do sleep 0.5; done

tailscale --socket=$SOCKET_PATH up --authkey="${TS_AUTHKEY}" --hostname="render-app" --accept-dns=false --shields-up=false

# Setup the internal mapping
tailscale --socket=$SOCKET_PATH serve --bg http://localhost:10000

# Toggle the public internet access
# Using 'on' first is the current standard
tailscale --socket=$SOCKET_PATH funnel on

echo "--- Final Status Check ---"
tailscale --socket=$SOCKET_PATH funnel status
echo "--------------------------"

exec node src/index.js
