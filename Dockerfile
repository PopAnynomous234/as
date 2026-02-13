# Use Node.js 20 on Alpine for small footprint
FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache curl iptables iproute2 bash

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of your code
COPY . .

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Set environment variables
# Replace <YOUR_KEY> with your Tailscale pre-auth key
ENV TAILSCALE_AUTHKEY=<YOUR_KEY>
ENV PORT=10000

# Start Tailscale daemon + Node server with PM2 for auto-restart
RUN npm install pm2 -g

CMD tailscaled --state=/tailscale/state.sock --tun=userspace-networking & \
    tailscale up --authkey=$TAILSCALE_AUTHKEY --accept-routes --accept-dns --funnel & \
    pm2 start index.js --name "app" --no-daemon
