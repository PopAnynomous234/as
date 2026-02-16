#!/bin/sh

SOCKET_PATH="/tmp/tailscaled.sock"

# 1. Start tailscaled in background
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --socket=$SOCKET_PATH --state=mem: &

# 2. Wait for socket
while [ ! -S $SOCKET_PATH ]; do sleep 0.5; done

# 3. Authenticate
tailscale --socket=$SOCKET_PATH up --authkey="${TS_AUTHKEY}" --hostname="render-app" --accept-dns=false --shields-up=false

# 4. THE 2026 WAY: Serve and Funnel in one step
# We use the --bg flag to keep it running in the background.
# This command tells Tailscale: "Serve my app on port 10000 to the public internet on 443"
echo "Starting Funnel..."
tailscale --socket=$SOCKET_PATH funnel --bg 10000

# 5. Status Verification
echo "--- Final Status Check ---"
tailscale --socket=$SOCKET_PATH funnel status
echo "--------------------------"

# 6. Start Node.js
echo "Starting Node.js application..."
exec node src/index.js
