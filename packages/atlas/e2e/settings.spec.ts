import { test, expect } from '@playwright/test';

test.describe('Settings Page', () => {
  test('page renders with provider and generation sections', async ({ page }) => {
    await page.goto('/settings');
    await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible();
    await expect(page.getByText('LLM Providers', { exact: true }).first()).toBeVisible();
    await expect(page.getByText('Generation Settings', { exact: true }).first()).toBeVisible();
  });

  test('add provider button opens dialog', async ({ page }) => {
    await page.goto('/settings');
    await page.getByRole('button', { name: 'Add Provider' }).click();

    await expect(page.getByText('Add New Provider')).toBeVisible();
    await expect(page.getByLabel('Name', { exact: false })).toBeVisible();
    await expect(page.getByLabel('API Key', { exact: false })).toBeVisible();
    await expect(page.getByLabel('Model', { exact: false })).toBeVisible();
  });

  test('dialog cancel button closes it', async ({ page }) => {
    await page.goto('/settings');
    await page.getByRole('button', { name: 'Add Provider' }).click();
    await expect(page.getByText('Add New Provider')).toBeVisible();

    await page.getByRole('button', { name: 'Cancel' }).click();
    await expect(page.getByText('Add New Provider')).not.toBeVisible();
  });

  test('generation settings load without error', async ({ page }) => {
    await page.goto('/settings');
    await expect(page.getByText('Failed to load settings.')).not.toBeVisible();
  });
});
