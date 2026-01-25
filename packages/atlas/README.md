# Node Generator Web Application

Full-stack web application for creating, editing, and browsing narrative graph nodes.

## Tech Stack

- **Frontend:** React + TypeScript + Tailwind CSS + shadcn/ui
- **Forms:** React Hook Form + Zod
- **State:** TanStack Query + Zustand
- **Backend:** Bun + Hono
- **Database:** PostgreSQL + Drizzle ORM
- **Deployment:** Docker Compose

## Project Structure

```
node-gen-web/
├── packages/
│   ├── shared/     # Shared Zod schemas, types, constants
│   ├── backend/    # Hono API + Drizzle ORM
│   └── frontend/   # React + Vite
├── docker-compose.yml
└── pnpm-workspace.yaml
```

## Getting Started

### Prerequisites

- Bun >= 1.0.0
- pnpm >= 8.0.0
- Docker & Docker Compose

### Installation

```bash
# Install dependencies
pnpm install

# Start PostgreSQL
pnpm docker:up

# Run migrations
pnpm db:migrate

# Seed database
pnpm db:seed

# Start all services
pnpm dev
```

### Access

- **Frontend:** http://localhost:5173
- **Backend API:** http://localhost:3000
- **Database:** postgresql://nodegen:nodegen_dev_password@localhost:5432/nodegen

## Development

```bash
# Type checking
pnpm typecheck

# Build all packages
pnpm build

# Database migrations
pnpm db:migrate

# Database seeding
pnpm db:seed

# Drizzle Studio (DB GUI)
pnpm --filter @node-gen-web/backend db:studio
```

## License

Private project - not for distribution
