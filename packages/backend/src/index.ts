import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { prettyJSON } from 'hono/pretty-json';
import { nodesRouter } from './routes/nodes.js';
import { configRouter } from './routes/config.js';
import { searchRouter } from './routes/search.js';
import generateRouter from './routes/generate.js';
import generateFieldRouter from './routes/generate-field.js';
import llmProvidersRouter from './routes/llm-providers.js';
import configAdvancedRouter from './routes/config-advanced.js';

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', prettyJSON());
app.use(
  '*',
  cors({
    origin: ['http://localhost:5173', 'http://localhost:3000'],
    credentials: true,
  })
);

// Health check
app.get('/health', (c) => {
  return c.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API routes
app.route('/api/nodes', nodesRouter);
app.route('/api/config', configRouter);
app.route('/api/search', searchRouter);
app.route('/api/generate', generateRouter);
app.route('/api/generate/field', generateFieldRouter);
app.route('/api/llm/providers', llmProvidersRouter);
app.route('/api/config/advanced', configAdvancedRouter);

// 404 handler
app.notFound((c) => {
  return c.json({ error: 'Not Found' }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error(`Error: ${err.message}`);
  console.error(err.stack);
  return c.json({ error: err.message || 'Internal Server Error' }, 500);
});

const port = parseInt(process.env.PORT || '3000');

console.log(`🚀 Server starting on port ${port}...`);

export default {
  port,
  fetch: app.fetch,
};
