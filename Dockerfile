# ===== 1. Base Image =====
FROM node:20-bullseye-slim

# ===== 2. Install dependencies =====
RUN apt-get update && \
    apt-get install -y curl gnupg2 lsb-release iproute2 iptables sudo ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ===== 3. Install Tailscale using apt with key =====
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.gpg | gpg --dearmor > /usr/share/keyrings/tailscale-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bullseye main" | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# ===== 4. Set working directory =====
WORKDIR /app

# ===== 5. Copy Node project =====
COPY package*.json ./
RUN npm install
COPY src ./src

# ===== 6. Expose Node port =====
EXPOSE 10000

# ===== 7. Set environment for Tailscale =====
ENV TS_AUTH_KEY=TS_AUTHKEY

# ===== 8. Start Tailscale and Node =====
CMD sh -c "\
    tailscaled --tun=userspace-networking --socks5-server=localhost:1055 & \
    sleep 5 && \
    tailscale up --authkey=$TS_AUTH_KEY --hostname=codelistener-proxy-2 --accept-routes --accept-dns & \
    node src/index.js \
"
