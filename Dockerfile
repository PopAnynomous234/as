# Use lightweight Node image
FROM node:20-alpine

# Install required packages
RUN apk add --no-cache \
    curl \
    iptables \
    ca-certificates

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Set working directory
WORKDIR /app

# Copy package files first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the app
COPY . .

# Render expects this port
ENV PORT=10000

# Start everything correctly
CMD sh -c '
echo "Starting tailscaled..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sleep 5

echo "Logging into Tailscale..."
tailscale up --authkey=${TS_AUTHKEY} --hostname=codelistener-proxy-2

echo "Enabling Funnel..."
tailscale funnel --yes 10000 &

echo "Starting Node app..."
exec node src/index.js
'
