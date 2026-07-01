FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json pnpm-lock.yaml* package-lock.json* yarn.lock* ./
RUN if [ -f pnpm-lock.yaml ]; then npm i -g pnpm && pnpm install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    else npm i; fi

COPY tsconfig.json .
COPY src ./src

RUN npx tsc

COPY --from=builder /app/dist ./dist

# Default port (can be overridden by PORT env)
EXPOSE 3000