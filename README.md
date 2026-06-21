# KeeperNet Backend

The high-performance indexer, scheduler, and transaction relayer for the KeeperNet automation protocol.

KeeperNet Backend is a robust TypeScript Node.js service that listens to Soroban smart contract events, tracks automation triggers (like block height or state changes), and safely relays executions back to the Stellar network using gas-aware fee-bumping and advanced sequence management.

[![Live Network Stats](https://img.shields.io/badge/Network%20Stats-Coming%20Soon-orange)](/)
[![API Documentation](https://img.shields.io/badge/API%20Docs-Read%20Now-blue)](/docs)
[![Contributing](https://img.shields.io/badge/Contributing-Welcome-green)](/CONTRIBUTING.md)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

---

## Core Features

| Feature | Description |
|---------|-------------|
| **Real-Time Indexer** | Subscribes to Soroban RPC to catch `JobRegistered` and `JobCancelled` events instantly |
| **Trigger Engine** | High-performance, multi-threaded state machine evaluating block heights and custom conditions against PostgreSQL |
| **Transaction Relayer** | Manages Stellar account sequence numbers, builds XDR execution envelopes, and applies fee-bumps to prevent stalled queues |
| **RESTful API** | Fast querying endpoints for the Next.js frontend to retrieve job states, execution logs, and network health metrics |
| **Simulation Guards** | Pre-simulates every automation trigger before submission to save gas on guaranteed panics |
| **Metrics Exporter** | Built-in Prometheus metrics for tracking relayer health, success rates, and RPC latency |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | TypeScript 5 |
| Runtime | Node.js >= 18 |
| Web Framework | Fastify |
| Database | PostgreSQL + Prisma ORM |
| Blockchain | Stellar SDK (JS), Soroban RPC Client |
| Testing | Vitest |
| Telemetry | pino + Prometheus |
| Containerization | Docker + Docker Compose |
| Reverse Proxy | Nginx |
| CI/CD | GitHub Actions |
| Git Hooks | Husky + lint-staged |

---

## Available API Routes

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/api/v0/health` | Relayer health and RPC connection status |
| `POST` | `/api/v0/jobs/simulate` | Validate a job registration payload |
| `GET` | `/api/v0/jobs/:job_id` | Fetch the current execution status of a specific job |
| `GET` | `/api/v0/jobs?owner=:address` | List all jobs registered by a specific user |
| `GET` | `/api/v0/network/metrics` | Global statistics — total executed, active nodes, avg gas |

---

## Project Structure

```text
├── src/
│   ├── api/                    # Fastify route handlers and JSON schema validators
│   ├── db/                     # Prisma client, migrations, and repository layer
│   ├── indexer/                # Soroban RPC event polling and log ingestion
│   ├── relayer/                # Sequence management and transaction submission
│   ├── engine/                 # The core trigger evaluation loop
│   └── main.ts                 # Application entry point and service orchestration
├── tests/
│   ├── unit/                   # Unit tests for engine, relayer, and indexer modules
│   ├── integration/            # Integration tests against a live local Postgres instance
│   └── mocks/                  # Shared mock factories and test fixtures
├── prisma/
│   ├── schema.prisma           # Database schema definition
│   └── migrations/             # Auto-generated Prisma migration files
├── nginx/
│   └── nginx.conf              # Nginx reverse proxy configuration
├── .github/
│   └── workflows/
│       ├── ci.yml              # Continuous integration pipeline
│       └── deploy.yml          # Production deployment workflow
├── .husky/
│   ├── pre-commit              # Lint and format checks before every commit
│   └── pre-push                # Full test suite before every push
├── Dockerfile                  # Multi-stage production Docker image
├── docker-compose.yml          # Local development stack (backend + postgres + nginx)
├── docker-compose.prod.yml     # Production stack configuration
├── package.json                # Node.js dependencies and scripts
├── tsconfig.json               # TypeScript compiler configuration
└── .env.example                # Example environment configuration
```

---

## Getting Started

### Prerequisites

- Node.js >= 18
- Docker >= 24 and Docker Compose >= 2.20
- PostgreSQL >= 14 (or run via Docker)
- Soroban CLI (for local network testing)

### Installation

```bash
# Clone the repository and navigate to the backend workspace
git clone https://github.com/YOUR_USERNAME/keepernet.git
cd keepernet/backend

# Install dependencies
npm install
```

### Environment Setup

```bash
cp .env.example .env
```

Configure the following variables in `.env`:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/keepernet
STELLAR_NETWORK=TESTNET
SOROBAN_RPC_URL=https://soroban-testnet.stellar.org
KEEPER_REGISTRY_ID=your-registry-contract-id
KEEPER_SECRET_KEY=S...
PORT=8000
```

> **Note:** `KEEPER_SECRET_KEY` is the Ed25519 secret key used to pay for and sign relayed transactions. See the [API Key Management](#api-key-management) section for secure handling guidance.

### Database Setup

```bash
# Run Prisma migrations
npx prisma migrate dev

# Generate Prisma client
npx prisma generate
```

### Running

```bash
# Development (with hot-reload)
npm run dev

# Type-check
npm run typecheck

# Lint
npm run lint

# Run all tests
npm run test

# Run unit tests only
npm run test:unit

# Run integration tests only
npm run test:integration

# Production build
npm run build

# Start production server
npm start
```

Open [http://localhost:8000/api/v0/health](http://localhost:8000/api/v0/health) to verify the service is running.

---

## Testing

All tests live in the `tests/` directory and are run with **Vitest**.

### Structure

```text
tests/
├── unit/
│   ├── engine.test.ts          # Trigger evaluation logic
│   ├── relayer.test.ts         # Sequence management and XDR building
│   └── indexer.test.ts         # Event polling and ingestion
├── integration/
│   ├── jobs.api.test.ts        # End-to-end API route testing
│   └── db.repository.test.ts  # Prisma repository layer against real Postgres
└── mocks/
    ├── stellar.mock.ts         # Mocked Stellar SDK responses
    └── db.mock.ts              # In-memory Prisma mock factory
```

### Running Tests

```bash
# Run all tests
npm run test

# Run with coverage report
npm run test:coverage

# Run in watch mode during development
npm run test:watch
```

### Integration Test Requirements

Integration tests require a running PostgreSQL instance. The easiest way to spin one up is via Docker:

```bash
docker compose up postgres -d
npm run test:integration
```

---

## Docker

### Local Development Stack

The `docker-compose.yml` file spins up the full local development environment — the backend service, PostgreSQL, and Nginx — in a single command.

```bash
# Build and start all services
docker compose up --build

# Run in detached mode
docker compose up -d

# Stop all services
docker compose down

# Stop and remove volumes (wipes the database)
docker compose down -v
```

The local stack exposes:

| Service | URL |
|---------|-----|
| Backend API (via Nginx) | http://localhost:80/api/v0 |
| Backend API (direct) | http://localhost:8000/api/v0 |
| PostgreSQL | localhost:5432 |

### Production Stack

```bash
# Build and start the production stack
docker compose -f docker-compose.prod.yml up -d --build

# View running containers
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f backend
```

### Dockerfile Overview

The backend uses a **multi-stage Docker build** to keep the production image lean:

```dockerfile
# Stage 1 — Builder
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 — Runtime
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/main.js"]
```

### Running Migrations in Docker

```bash
docker compose exec backend npx prisma migrate deploy
```

---

## Nginx

Nginx acts as a reverse proxy sitting in front of the backend, handling SSL termination, request routing, and rate limiting.

### Local Configuration (`nginx/nginx.conf`)

```nginx
server {
    listen 80;

    location /api/v0/ {
        proxy_pass         http://backend:8000;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Production Configuration

In production, Nginx additionally handles:

- **SSL/TLS termination** via Let's Encrypt certificates
- **Rate limiting** on the `/api/v0/jobs/simulate` endpoint to prevent abuse
- **Gzip compression** for all JSON API responses
- **Request size limits** to guard against oversized payloads

---

## GitHub Actions Workflows

All CI/CD pipelines live in `.github/workflows/`.

### CI Pipeline (`ci.yml`)

Runs on every pull request and push to `main`:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm run test:coverage
```

### Deploy Pipeline (`deploy.yml`)

Runs on every push to `main` after CI passes:

```yaml
jobs:
  deploy:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and push Docker image
        run: |
          docker build -t keepernet-backend .
          docker push your-registry/keepernet-backend:latest
      - name: Restart production service
        run: ssh deploy@your-server "docker compose -f docker-compose.prod.yml pull && docker compose -f docker-compose.prod.yml up -d"
```

> Sensitive values like `KEEPER_SECRET_KEY`, `DATABASE_URL`, and SSH credentials are stored as **GitHub Actions Secrets** and injected at runtime — never hardcoded in workflow files.

---

## Husky Git Hooks

Husky enforces code quality gates locally before code ever reaches the remote repository.

### Setup

Husky is initialized automatically after running `npm install` via the `prepare` script in `package.json`:

```json
{
  "scripts": {
    "prepare": "husky install"
  }
}
```

### Pre-Commit Hook (`.husky/pre-commit`)

Runs fast checks before every `git commit` using `lint-staged`:

```bash
#!/bin/sh
npx lint-staged
```

`lint-staged` is configured in `package.json` to only process staged files:

```json
{
  "lint-staged": {
    "src/**/*.ts": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}
```

### Pre-Push Hook (`.husky/pre-push`)

Runs the full test suite and type check before every `git push`:

```bash
#!/bin/sh
set -e
npm run typecheck
npm run test
```

If any of these checks fail, the push is blocked until the issue is resolved.

---

## API Key Management

The KeeperNet backend relies on a small set of sensitive credentials that must be handled carefully across all environments.

### Keys and Secrets Overview

| Key | Description | Sensitivity |
|-----|-------------|-------------|
| `KEEPER_SECRET_KEY` | Ed25519 private key used to sign and pay for all relayed transactions | Critical |
| `DATABASE_URL` | Full PostgreSQL connection string including username and password | High |
| `SOROBAN_RPC_URL` | RPC endpoint for Stellar network access | Medium |
| `KEEPER_REGISTRY_ID` | On-chain contract address for the job registry | Low |

### Local Development

For local development, secrets are loaded from the `.env` file via the `dotenv` package. This file is listed in `.gitignore` and must **never** be committed to version control.

```bash
KEEPER_SECRET_KEY=SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Staging and Production

In staging and production environments, plaintext `.env` files are not acceptable. Use one of the following approaches:

**Option 1 — AWS Secrets Manager (Recommended)**

```typescript
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const client = new SecretsManagerClient({ region: "us-east-1" });
const response = await client.send(
  new GetSecretValueCommand({ SecretId: "keepernet/prod/keeper-secret-key" })
);
const keeperKey = response.SecretString;
```

**Option 2 — HashiCorp Vault**

```bash
vault agent -config=vault-agent-config.hcl
```

**Option 3 — GitHub Actions Secrets + Docker Compose**

```yaml
- name: Deploy Backend
  env:
    KEEPER_SECRET_KEY: ${{ secrets.KEEPER_SECRET_KEY }}
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Key Rotation

When rotating the `KEEPER_SECRET_KEY`:

1. Generate a new Ed25519 keypair: `stellar keys generate new-keeper`
2. Fund the new account on the target network
3. Update the secret in your vault or CI/CD environment
4. Restart the backend — the new key is loaded at startup
5. Monitor `/api/v0/health` to confirm the relayer reconnects cleanly
6. Revoke or archive the old key

### What Not To Do

- Never commit `.env` files or hardcode secrets in source code
- Never log the `KEEPER_SECRET_KEY` value, even at debug level
- Never share production keys in Slack, email, or issue trackers
- Never reuse the same keypair across testnet and mainnet

---

## Architecture Notes

**Service Orchestration** — The indexer, API server, and relayer loop run as concurrent async workers within the same Node.js process, communicating state changes via an internal event emitter and the PostgreSQL database.

**Sequence Management** — To prevent transaction failures when firing multiple triggers simultaneously, the relayer maintains an in-memory lock on the keeper wallet's sequence number, flushing to the network in strict, ordered batches.

**Prisma Migrations** — All schema changes are managed through Prisma migrations. Never modify the database schema manually. Always run `npx prisma migrate dev` to generate and apply migration files.

---

## Security

**Key Management** — `KEEPER_SECRET_KEY` has full authority over the relayer's funds. In production, inject it via a secure vault rather than a plaintext `.env` file. See [API Key Management](#api-key-management) above.

**Payload Validation** — All incoming job payloads are validated against strict JSON schemas at the Fastify route layer before any processing occurs.

**Gas Limits** — The relayer enforces strict gas limits on automated executions to prevent malicious contracts from draining the relayer's wallet.

---

## Roadmap

### Planned

- [ ] PostgreSQL schema and Prisma integration
- [ ] Basic Soroban event polling loop
- [ ] Fastify REST API scaffolding
- [ ] Relayer engine — safe sequence number management and XDR generation
- [ ] Trigger evaluator — block-height matching logic
- [ ] Fee-bumping strategy — dynamic fee adjustment based on network congestion
- [ ] State-based triggers — executing jobs based on arbitrary contract reads
- [ ] WebSocket server — streaming execution logs to the Next.js frontend
- [ ] Multi-key sharding — using an array of keeper keys to increase parallel execution throughput
- [ ] Docker and Docker Compose local and production stack setup
- [ ] Nginx reverse proxy with SSL termination and rate limiting
- [ ] GitHub Actions CI/CD pipelines
- [ ] Husky pre-commit and pre-push git hooks

---

## Contributing

We welcome contributions. If you are interested in TypeScript, distributed systems, and blockchain infrastructure, this is the perfect place to jump in.

### Quick Start for Contributors

1. **Find an issue** — Check `good first issues` or `help wanted` on the issues board
2. **Read the guide** — See [CONTRIBUTING.md](CONTRIBUTING.md)
3. **Set up locally** — Follow the setup instructions above
4. **Make your changes** — Create a feature branch
5. **Test** — Ensure `npm run test` and `npm run lint` pass
6. **Submit a PR** — Open a pull request with a clear description

---

## Community and Support

- **Documentation** — [Full Docs](/docs)
- **Issues** — [Report bugs or request features](../../issues)
- **Discussions** — [Stellar Community Forum](https://community.stellar.org)

---

## License

MIT License — Copyright (c) 2026 KeeperNet Protocol.

---

*Automating the future of Soroban, one block at a time.*
