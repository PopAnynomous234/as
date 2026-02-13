FROM node:18-alpine

RUN apk add --no-cache ca-certificates tailscale python3 make g++ coreutils && \
    corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

COPY ["package.json", "pnpm-lock.yaml*", "./"]
RUN pnpm install --prod

COPY . .

EXPOSE 10000

ENTRYPOINT mkdir -p /var/lib/tailscale /var/run/tailscale && \
tailscaled --tun=userspace-networking & \
sleep 5 && \
tailscale up --authkey="$TS_AUTHKEY" --hostname=codelistener-proxy && \
tailscale serve --http=10000 && \
tailscale funnel 10000 && \
exec node src/index.js
