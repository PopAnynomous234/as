FROM node:18-alpine

# Install Tailscale and dependencies
RUN apk add --no-cache ca-certificates tailscale python3 make g++ && \
    corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app
COPY ["package.json", "pnpm-lock.yaml*", "./"]
RUN pnpm install --prod
COPY . .

# Copy a start script (we will create this next)
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 10000
ENTRYPOINT ["/app/start.sh"]
