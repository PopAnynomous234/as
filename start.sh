#!/bin/sh

# 1. Setup paths
SOCKET_PATH="/tmp/tailscaled.sock"

# 2. Start tailscaled in userspace mode
# Added --state=mem: to ensure no disk write errors on Render
tailscaled --tun=userspace-networking \
           --socks5-server=localhost:1055 \
           --socket=$SOCKET_PATH \
           --state=mem: &

# 3. Wait for the socket
echo "Waiting for Tailscale socket..."
while [ ! -S $SOCKET_PATH ]; do
  sleep 0.5
done

# 4. Authenticate and ensure Shields are DOWN
# --shields-up=false is critical to allow Funnel traffic in
echo "Authenticating Tailscale..."
tailscale --socket=$SOCKET_PATH up \
          --authkey="${TS_AUTHKEY}" \
          --hostname="render-app" \
          --accept-dns=false \
          --shields-up=false

# 5. Configure the Funnel
# We use 'serve' to tell Tailscale HOW to handle the traffic (HTTP inside, HTTPS outside)
echo "Configuring Funnel..."
tailscale --socket=$SOCKET_PATH serve --bg https:443 / http://localhost:10000
tailscale --socket=$SOCKET_PATH funnel 443 on

# 6. Debug: Print the funnel status to Render logs
echo "--- Funnel Status ---"
tailscale --socket=$SOCKET_PATH funnel status
echo "----------------------"

# 7. Start your Node app
# Ensure your app listens on 0.0.0.0:10000
echo "Starting Node.js application..."
exec node src/index.js
