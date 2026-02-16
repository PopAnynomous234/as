#!/bin/sh

SOCKET_PATH="/tmp/tailscaled.sock"

# 1. Start tailscaled
tailscaled --tun=userspace-networking \
           --socks5-server=localhost:1055 \
           --socket=$SOCKET_PATH \
           --state=mem: &

# 2. Wait for socket
while [ ! -S $SOCKET_PATH ]; do sleep 0.5; done

# 3. Authenticate
tailscale --socket=$SOCKET_PATH up \
          --authkey="${TS_AUTHKEY}" \
          --hostname="render-app" \
          --accept-dns=false

# 4. NEW SYNTAX: Define the local "Serve" config
# This tells Tailscale to take local port 10000 and map it to the tailnet
tailscale --socket=$SOCKET_PATH serve --bg http://localhost:10000

# 5. NEW SYNTAX: Turn on the "Funnel" (Public Access)
# This opens the serve config to the internet on port 443
tailscale --socket=$SOCKET_PATH funnel 443 on

# 6. Verify Status
echo "--- Tailscale Funnel Status ---"
tailscale --socket=$SOCKET_PATH funnel status
echo "-------------------------------"

# 7. Start Node
exec node src/index.js
