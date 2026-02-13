# ===== 1. Base image =====
FROM node:20-bullseye-slim

# ===== 2. Install required packages =====
RUN apt-get update && apt-get install -y \
    curl \
    iproute2 \
    iptables \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ===== 3. Install Tailscale =====
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.gpg | gpg --dearmor -o /usr/share/keyrings/tailscale-archive-keyring.gpg
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.list | tee /etc/apt/sources.list.d/tailscale.list
RUN apt-get update && apt-get install -y tailscale

# ===== 4. Set working directory =====
WORKDIR /app

# ===== 5. Copy package.json and install dependencies =====
COPY package*.json ./
RUN npm install

# ===== 6. Copy all project files =====
COPY . .

# ===== 7. Expose the port your Node server listens on =====
EXPOSE 10000

# ===== 8. Start Tailscale + Node server =====
CMD tailscaled --state=/tailscale/state.sock --tun=userspace-networking & \
    tailscale up --authkey=$TS_AUTHKEY --accept-routes --accept-dns --funnel & \
    node index.js
