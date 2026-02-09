#!/bin/sh

# Start tailscaled in the background
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait for tailscaled to be ready, then log in using the Auth Key
tailscale up --authkey=${TS_AUTHKEY} --hostname=codelistener-proxy

# Turn on the Funnel for port 10000 (Render's port)
tailscale funnel 10000 on

# Start your Scramjet app
node src/index.js
