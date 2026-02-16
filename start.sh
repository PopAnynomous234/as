#!/bin/sh

# Start tailscaled in userspace mode
tailscaled --state=mem: --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait for tailscaled to be ready
until tailscale status >/dev/null 2>&1; do
  sleep 1
done

# Authenticate with Tailscale
# We use --accept-dns=false usually to avoid overwriting Render's internal DNS
tailscale up --authkey="${TS_AUTHKEY}" --hostname="render-app" --nopreview

# Start your Node application
echo "Starting Node.js..."
exec node src/index.js
