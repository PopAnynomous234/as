#!/bin/sh

# 1. Start the daemon with a state file in memory (important for Render)
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --state=mem: &

# 2. Wait until tailscaled is actually responsive
until tailscale status >/dev/null 2>&1; do
  echo "Waiting for tailscaled..."
  sleep 1
done

# 3. Authenticate and set hostname
tailscale up --authkey="${TS_AUTHKEY}" --hostname="render-app" --accept-dns=false

# 4. Turn on the Funnel 
# We run this in the background (&) so it doesn't block your app starting
tailscale funnel 10000 &

# 5. Start your actual application
echo "Tailscale is up! Starting Node.js..."
exec node src/index.js
