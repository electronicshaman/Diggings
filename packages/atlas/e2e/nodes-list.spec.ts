import { test, expect } from '@playwright/test';
import { createCombatNode, createChoiceNode } from './fixtures/test-data';
import { createNodeViaAPI, deleteNodeViaAPI } from './fixtures/api-helpers';

let combatNode: { nodeId: string; name: string };
let choiceNode: { nodeId: string; name: string };

test.beforeAll(async () => {
  const combatData = createCombatNode();
  const choiceData = createChoiceNode();
  combatNode = await createNodeViaAPI(combatData);
  choiceNode = await createNodeViaAPI(choiceData);
});

test.afterAll(async () => {
  await deleteNodeViaAPI(combatNode.nodeId);
  await deleteNodeViaAPI(choiceNode.nodeId);
});

test.describe('Node List', () => {
  test('displays both test nodes', async ({ page }) => {
    await page.goto('/nodes');
    await expect(page.getByText(combatNode.name)).toBeVisible();
    await expect(page.getByText(choiceNode.name)).toBeVisible();
  });

  test('search filters nodes', async ({ page }) => {
    await page.goto('/nodes');
    await expect(page.getByText(combatNode.name)).toBeVisible();

    await page.getByPlaceholder('Search nodes...').fill('Combat');
    // Wait for 300ms debounce + rendering
    await page.waitForTimeout(500);

    await expect(page.getByText(combatNode.name)).toBeVisible();
    await expect(page.getByText(choiceNode.name)).not.toBeVisible();
  });

  test('type filter works', async ({ page }) => {
    await page.goto('/nodes');
    await expect(page.getByText(combatNode.name)).toBeVisible();

    // The Type combobox shows "All types" by default
    await page.getByRole('combobox').nth(0).click();
    await page.getByRole('option', { name: 'Combat' }).click();

    await expect(page.getByText(combatNode.name)).toBeVisible();
    await expect(page.getByText(choiceNode.name)).not.toBeVisible();
  });

  test('biome filter works', async ({ page }) => {
    await page.goto('/nodes');
    await expect(page.getByText(combatNode.name)).toBeVisible();

    // The Biome combobox is the second one
    await page.getByRole('combobox').nth(1).click();
    await page.getByRole('option', { name: 'Township' }).click();

    await expect(page.getByText(choiceNode.name)).toBeVisible();
    await expect(page.getByText(combatNode.name)).not.toBeVisible();
  });

  test('view toggle switches between cards and table', async ({ page }) => {
    await page.goto('/nodes');
    await expect(page.getByText(combatNode.name)).toBeVisible();

    // Switch to table view
    await page.getByRole('button', { name: 'Table view' }).click();
    await expect(page.getByRole('columnheader', { name: 'Name' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: 'Type' })).toBeVisible();

    // Switch back to cards view
    await page.getByRole('button', { name: 'Cards view' }).click();
    await expect(page.getByRole('columnheader', { name: 'Name' })).not.toBeVisible();
  });
});
