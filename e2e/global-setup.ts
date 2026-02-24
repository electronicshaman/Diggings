import { execSync } from 'child_process';
import { test as setup } from '@playwright/test';

setup('ensure database is ready', async () => {
  // Check if postgres is already reachable; if not, try starting via Docker
  let pgReady = false;
  try {
    execSync('pg_isready -U nodegen -h localhost -p 5432', { stdio: 'pipe' });
    pgReady = true;
    console.log('Postgres is already running');
  } catch {
    // Not reachable — try Docker
    console.log('Postgres not reachable, attempting docker-compose...');
    try {
      execSync('docker-compose up -d postgres', { stdio: 'inherit' });
    } catch {
      throw new Error(
        'Postgres is not running and docker-compose failed. Start postgres manually or run: pnpm docker:up',
      );
    }
  }

  // Wait for postgres to be ready (up to 30s) if not already
  if (!pgReady) {
    const maxAttempts = 30;
    for (let i = 0; i < maxAttempts; i++) {
      try {
        execSync('pg_isready -U nodegen -h localhost -p 5432', {
          stdio: 'pipe',
        });
        console.log('Postgres is ready');
        break;
      } catch {
        if (i === maxAttempts - 1) {
          throw new Error('Postgres did not become ready within 30s');
        }
        execSync('sleep 1');
      }
    }
  }

  // Run migrations and seed
  console.log('Running migrations...');
  execSync('pnpm db:migrate', { stdio: 'inherit' });

  console.log('Seeding database...');
  execSync('pnpm db:seed', { stdio: 'inherit' });

  console.log('Global setup complete');
});
