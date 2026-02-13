FROM node:18-alpine

# Install Tailscale and dependencies
RUN apk add --no-cache ca-certificates tailscale python3 make g++ coreutils && \
    corepack enable && corepack prepare pnpm@latest --activate

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY ["package.json", "pnpm-lock.yaml*", "./"]
RUN pnpm install --prod

# Copy app code
COPY . .

# Expose port
EXPOSE 10000

# Single-line ENTRYPOINT
ENTRYPOINT mkdir -p /var/lib/tailscale /var/run/tailscale && \
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 & \
sleep 5 && \
tailscale up --authkey="$TS_AUTHKEY" --hostname=codelistener-proxy && \
tailscale funnel 10000 on && \
exec node src/index.js
