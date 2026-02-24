import { request } from '@playwright/test';

const API_BASE = 'http://localhost:3000/api';

export async function createNodeViaAPI(data: Record<string, unknown>) {
  const ctx = await request.newContext();
  const res = await ctx.post(`${API_BASE}/nodes`, { data });
  if (!res.ok()) {
    const body = await res.text();
    throw new Error(`Failed to create node: ${res.status()} ${body}`);
  }
  const json = await res.json();
  await ctx.dispose();
  return json;
}

export async function deleteNodeViaAPI(nodeId: string) {
  const ctx = await request.newContext();
  const res = await ctx.delete(`${API_BASE}/nodes/${nodeId}`);
  // Tolerate 404 — node may already be deleted
  if (!res.ok() && res.status() !== 404) {
    const body = await res.text();
    throw new Error(`Failed to delete node: ${res.status()} ${body}`);
  }
  await ctx.dispose();
}

export async function healthCheck() {
  const ctx = await request.newContext();
  const res = await ctx.get('http://localhost:3000/health');
  const json = await res.json();
  await ctx.dispose();
  return json;
}
