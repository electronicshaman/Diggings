import { test, expect } from '@playwright/test';

test.describe('Smoke Tests', () => {
  test('backend health endpoint returns ok', async ({ request }) => {
    const res = await request.get('http://localhost:3000/health');
    expect(res.ok()).toBe(true);
    const json = await res.json();
    expect(json.status).toBe('ok');
  });

  test('GET /api/nodes succeeds (DB connection works)', async ({ request }) => {
    const res = await request.get('/api/nodes');
    expect(res.ok()).toBe(true);
    const json = await res.json();
    expect(json).toHaveProperty('data');
  });

  test('frontend loads with sidebar navigation', async ({ page }) => {
    await page.goto('/');
    const sidebar = page.locator('nav');
    await expect(sidebar.getByText('All Nodes')).toBeVisible();
    await expect(sidebar.getByText('AI Generate')).toBeVisible();
    await expect(sidebar.getByText('Configuration')).toBeVisible();
    await expect(sidebar.getByText('Advanced Config')).toBeVisible();
    await expect(sidebar.getByText('Settings')).toBeVisible();
  });

  test('node list page shows no DB error', async ({ page }) => {
    await page.goto('/nodes');
    await expect(page.getByRole('heading', { name: 'Nodes' })).toBeVisible();
    await expect(page.getByText('Failed to load nodes')).not.toBeVisible();
  });

  test('sidebar navigation works', async ({ page }) => {
    await page.goto('/nodes');

    await page.getByRole('link', { name: 'AI Generate' }).click();
    await expect(page).toHaveURL(/\/generate/);

    await page.getByRole('link', { name: 'Configuration' }).click();
    await expect(page).toHaveURL(/\/config$/);

    await page.getByRole('link', { name: 'Advanced Config' }).click();
    await expect(page).toHaveURL(/\/config\/advanced/);

    await page.getByRole('link', { name: 'Settings' }).click();
    await expect(page).toHaveURL(/\/settings/);

    await page.getByRole('link', { name: 'All Nodes' }).click();
    await expect(page).toHaveURL(/\/nodes/);
  });
});
