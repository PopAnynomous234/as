FROM node:18-alpine

# 1. Enable pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

ENV NODE_ENV=production
# We change the build arg to use pnpm
ARG NPM_BUILD="pnpm install --prod"
EXPOSE 8080/tcp

LABEL maintainer="Mercury Workshop"

WORKDIR /app

# 2. Update this to look for pnpm-lock.yaml instead of package-lock.json
COPY ["package.json", "pnpm-lock.yaml", "./"]

# 3. Add build dependencies for native modules
RUN apk add --upgrade --no-cache python3 make g++

# 4. Run the pnpm install
RUN $NPM_BUILD

COPY . .

ENTRYPOINT [ "node" ]
# 5. Ensure this path is correct for your project structure
CMD ["src/index.js"]
