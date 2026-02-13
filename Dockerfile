# Use Node 20 on Debian
FROM node:20-bullseye

# Install dependencies required by Tailscale
RUN apt-get update && apt-get install -y \
    curl iproute2 iptables sudo && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of your code
COPY . .

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Environment variables
ENV TAILSCALE_AUTHKEY=<YOUR_KEY>
ENV PORT=10000

# Start Tailscale + Node app
CMD tailscaled --state=/tailscale/state.sock --tun=userspace-networking & \
    tailscale up --authkey=$TAILSCALE_AUTHKEY --accept-routes --accept-dns --funnel & \
    node index.js
