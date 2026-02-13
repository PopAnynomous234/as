#!/bin/sh
set -e

# Ensure Tailscale directories exist
mkdir -p /var/lib/tailscale /var/run/tailscale

# Start tailscaled in the background
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Give tailscaled a few seconds to start
sleep 5

# Authenticate using Tailscale auth key
tailscale up --authkey="${TS_AUTHKEY}" --hostname=codelistener-proxy

# Enable Funnel for Render's port
tailscale funnel 10000 on

# Start the Node app
exec node src/index.js
