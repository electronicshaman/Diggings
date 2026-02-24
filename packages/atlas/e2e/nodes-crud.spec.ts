import { test, expect } from '@playwright/test';
import { createCombatNode } from './fixtures/test-data';
import { createNodeViaAPI, deleteNodeViaAPI } from './fixtures/api-helpers';

const uniqueName = `E2E Wizard ${Date.now()}`;

test.describe('Node Create Wizard', () => {
  test('create a combat node via wizard', async ({ page }) => {
    await page.goto('/nodes/create');

    // Step 0: Select type — click "Battle encounters with enemies" card
    await page.getByText('Battle encounters with enemies').click();

    // Step 1: Base fields
    await expect(page.getByText('Base Fields')).toBeVisible();
    await page.getByLabel('Name', { exact: false }).fill(uniqueName);

    // Select biome
    await page.locator('button[role="combobox"]').first().click();
    await page.getByRole('option', { name: 'The Bush' }).click();

    // Check Act 1 and Act 2 (labels are "1: Arrival", "2: Fever")
    const act1 = page.getByRole('checkbox', { name: '1: Arrival' });
    const act2 = page.getByRole('checkbox', { name: '2: Fever' });
    if (!(await act1.isChecked())) await act1.check();
    if (!(await act2.isChecked())) await act2.check();

    await page.getByRole('button', { name: 'Next' }).click();

    // Step 2: Type-specific (combat) — select at least one enemy type hook
    await expect(page.getByText('Combat Properties')).toBeVisible();
    await expect(page.getByText('Enemy Type Hooks')).toBeVisible();
    const firstEnemyCheckbox = page.locator('label').filter({ hasText: /./}).locator('button[role="checkbox"]').first();
    await firstEnemyCheckbox.waitFor({ state: 'visible', timeout: 10_000 });
    await firstEnemyCheckbox.check();
    await page.getByRole('button', { name: 'Next' }).click();

    // Step 3: Eligibility — just advance
    await expect(page.getByRole('heading', { name: 'Eligibility Conditions' })).toBeVisible();
    await page.getByRole('button', { name: 'Next' }).click();

    // Step 4: Review — submit
    await expect(page.getByText('Review & Create')).toBeVisible();

    const responsePromise = page.waitForResponse(
      (resp) => resp.url().includes('/api/nodes') && resp.request().method() === 'POST',
      { timeout: 15_000 },
    );
    await page.getByRole('button', { name: 'Create Node' }).click();
    const response = await responsePromise;
    expect(response.status()).toBe(201);

    // Wait for redirect to detail page
    await page.waitForURL(/\/nodes\/(?!create)/, { timeout: 15_000 });
    await expect(page.getByText(uniqueName)).toBeVisible({ timeout: 10_000 });
  });
});

test.describe.serial('Node Edit & Delete', () => {
  let nodeId: string;
  const nodeName = `CRUD Test ${Date.now()}`;

  test.beforeAll(async () => {
    const data = createCombatNode({ name: nodeName });
    const created = await createNodeViaAPI(data);
    nodeId = created.nodeId;
  });

  test.afterAll(async () => {
    if (nodeId) await deleteNodeViaAPI(nodeId);
  });

  test('edit page loads with node data', async ({ page }) => {
    await page.goto(`/nodes/${nodeId}/edit`);
    await expect(page.getByRole('heading', { name: 'Edit Node' })).toBeVisible({ timeout: 10_000 });
    await expect(page.getByLabel('Name *')).toHaveValue(nodeName);
    await expect(page.getByRole('button', { name: 'Save Changes' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Cancel' })).toBeVisible();
  });

  test('delete the node', async ({ page }) => {
    await page.goto(`/nodes/${nodeId}`);
    await expect(page.getByText(nodeName)).toBeVisible({ timeout: 10_000 });

    // Click Delete button
    await page.getByRole('button', { name: 'Delete' }).click();

    // Confirm in dialog
    await expect(page.getByText('Are you sure')).toBeVisible();
    await page.getByRole('dialog').getByRole('button', { name: 'Delete' }).click();

    // Should redirect to /nodes
    await expect(page).toHaveURL(/\/nodes$/, { timeout: 10_000 });
    // Node should be gone — mark for cleanup skip
    nodeId = '';
  });
});
