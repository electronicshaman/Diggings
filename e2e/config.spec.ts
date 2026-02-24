import { test, expect } from '@playwright/test';

test.describe('Configuration Page', () => {
  test('distributions tab shows target matrix', async ({ page }) => {
    await page.goto('/config');
    await expect(page.getByText('Target Node Distribution')).toBeVisible();
    await expect(page.getByText('Township')).toBeVisible();
    // Check node type column headers exist
    await expect(page.getByRole('columnheader', { name: 'Combat' })).toBeVisible();
    await expect(page.getByRole('columnheader', { name: 'Choice' })).toBeVisible();
  });

  test('current stats tab shows stats', async ({ page }) => {
    await page.goto('/config');
    await page.getByRole('tab', { name: 'Current Stats' }).click();
    await expect(page.getByText('Current Stats vs Targets')).toBeVisible();
    await expect(page.getByText('Total Nodes:')).toBeVisible();
    await expect(page.getByText('By Type')).toBeVisible();
    await expect(page.getByText('By Biome')).toBeVisible();
  });

  test('biomes tab shows biome cards', async ({ page }) => {
    await page.goto('/config');
    await page.getByRole('tab', { name: 'Biomes' }).click();
    await expect(page.getByText('Themes').first()).toBeVisible();
  });
});
