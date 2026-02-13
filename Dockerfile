# ===== 1. Base image =====
FROM node:20-bullseye-slim

# ===== 2. Install system dependencies =====
RUN apt-get update && apt-get install -y \
    curl \
    iproute2 \
    iptables \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ===== 3. Add Tailscale repository and key =====
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.gpg | gpg --dearmor > /usr/share/keyrings/tailscale-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bullseye main" \
       > /etc/apt/sources.list.d/tailscale.list

# ===== 4. Install Tailscale =====
RUN apt-get update && apt-get install -y tailscale \
    && rm -rf /var/lib/apt/lists/*

# ===== 5. Set working directory =====
WORKDIR /app

# ===== 6. Copy package files and install Node dependencies =====
COPY package*.json ./
RUN npm install

# ===== 7. Copy application code =====
COPY . .

# ===== 8. Expose your app port =====
ENV PORT=10000
EXPOSE 10000

# ===== 9. Start Tailscale and Node server =====
# We will use a small shell script to keep Tailscale up and start your server
CMD ["sh", "-c", "\
  tailscaled --tun=userspace-networking --socks5-server=localhost:1055 & \
  tailscale up --accept-routes --hostname=codelistener --authkey=${TS_AUTHKEY} & \
  node index.js \
"]
