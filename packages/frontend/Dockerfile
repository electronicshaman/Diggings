FROM oven/bun:1-alpine

WORKDIR /app

# Copy package files
COPY package.json ./
COPY ../../pnpm-workspace.yaml ../../

# Install dependencies
RUN bun install

# Copy source
COPY . .

EXPOSE 5173

CMD ["bun", "run", "dev", "--host"]
