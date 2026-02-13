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

# Copy the start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose your app port
EXPOSE 10000

# Start command
ENTRYPOINT ["/app/start.sh"]
