FROM node:20-alpine

RUN apk add --no-cache \
    curl \
    iptables \
    ca-certificates

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV PORT=10000

CMD ["sh", "-c", "tailscaled --tun=userspace-networking --socks5-server=localhost:1055 & sleep 5 && tailscale up --authkey=${TS_AUTHKEY} --hostname=codelistener-proxy-2 && tailscale funnel --yes 10000 & exec node src/index.js"]
