#!/bin/sh

# 1. Define where the socket lives
SOCKET_PATH="/tmp/tailscaled.sock"

# 2. Start the daemon with the explicit socket path
# We also add --state=mem: to avoid disk permission errors
tailscaled --tun=userspace-networking \
           --socks5-server=localhost:1055 \
           --socket=$SOCKET_PATH \
           --state=mem: &

# 3. Wait for the socket file to actually exist on disk
echo "Waiting for $SOCKET_PATH to appear..."
while [ ! -S $SOCKET_PATH ]; do
  sleep 0.5
done

# 4. Run 'up' but point it to the SAME socket
echo "Socket found! Authenticating..."
tailscale --socket=$SOCKET_PATH up \
          --authkey="${TS_AUTHKEY}" \
          --hostname="render-app" \
          --accept-dns=false

# 5. Start Funnel (pointing to socket again)
tailscale --socket=$SOCKET_PATH funnel 10000 &

# 6. Start Node
echo "Tailscale is ready. Starting Node.js..."
exec node src/index.js
