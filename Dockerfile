FROM node:20-slim

# Install curl + required networking tools
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    iptables \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV PORT=10000

CMD ["sh", "-c", "tailscaled --tun=userspace-networking --socks5-server=localhost:1055 & sleep 5 && tailscale up --authkey=${TS_AUTHKEY} --hostname=codelistener-proxy-2 && tailscale funnel --yes 10000 & exec node src/index.js"]
