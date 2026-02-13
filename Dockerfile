# Use Node 20 Alpine
FROM node:20-alpine

# Install dependencies required by Tailscale
RUN apk add --no-cache curl bash iptables iproute2

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of your code
COPY . .

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | bash

# Environment variables
# Replace <YOUR_KEY> with your pre-auth key
ENV TAILSCALE_AUTHKEY=<YOUR_KEY>
ENV PORT=10000

# Install PM2 to keep server alive
RUN npm install pm2 -g

# Start Tailscale + Node app
CMD tailscaled --state=/tailscale/state.sock --tun=userspace-networking & \
    tailscale up --authkey=$TAILSCALE_AUTHKEY --accept-routes --accept-dns --funnel & \
    pm2 start index.js --name "app" --no-daemon
