# Start the daemon in the background
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --state=mem: &

# Give it a moment to initialize the socket
sleep 2

# Now run the 'up' command
tailscale up --authkey=${TS_AUTHKEY} --hostname=render-app --accept-dns=false
