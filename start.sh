#!/bin/sh

# 1. Setup paths
SOCKET_PATH="/tmp/tailscaled.sock"

# 2. Start tailscaled in userspace mode
# Use --state=mem: to avoid disk permission errors on Render
tailscaled --tun=userspace-networking \
           --socks5-server=localhost:1055 \
           --socket=$SOCKET_PATH \
           --state=mem: &

# 3. Wait for the socket file to exist
echo "Waiting for Tailscale socket..."
while [ ! -S $SOCKET_PATH ]; do
  sleep 0.5
done

# 4. Authenticate
# --shields-up=false is critical to allow external traffic to reach the app
echo "Authenticating Tailscale..."
tailscale --socket=$SOCKET_PATH up \
          --authkey="${TS_AUTHKEY}" \
          --hostname="render-app" \
          --accept-dns=false \
          --shields-up=false

# 5. Configure the local mapping (Serve)
# This maps your Node app on 10000 to the Tailscale network
echo "Setting up local serve..."
tailscale --socket=$SOCKET_PATH serve --bg http://localhost:10000

# 6. Enable the Funnel (Public Internet Access)
# Using the --set-public flag is the most reliable way to avoid CLI syntax errors
echo "Enabling Funnel..."
tailscale --socket=$SOCKET_PATH funnel --set-public=true 443

# 7. Verification block
echo "--- Final Status Check ---"
tailscale --socket=$SOCKET_PATH funnel status
echo "--------------------------"

# 8. Start your Node application
echo "Tailscale is ready. Starting Node.js..."
exec node src/index.js
