# ===== 1. Base Image =====
FROM node:20-bullseye-slim

# ===== 2. Install dependencies =====
# Cleaned up unnecessary packages to reduce image size
RUN apt-get update && \
    apt-get install -y curl gnupg2 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ===== 3. Install Tailscale =====
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.gpg | gpg --dearmor > /usr/share/keyrings/tailscale-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bullseye main" | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# ===== 4. Set working directory =====
WORKDIR /app

# ===== 5. Copy Node project =====
COPY package*.json ./
RUN npm install --production
COPY . .

# ===== 6. Networking Configuration =====
# Render's default port is usually 10000
EXPOSE 10000

# ===== 7. Startup Script =====
# We move the logic to a script for better signal handling (CTRL+C / SIGTERM)
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
