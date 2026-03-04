import { test, expect } from '@playwright/test';

test.describe('AI Generate Page', () => {
  test('page shows heading and three tabs', async ({ page }) => {
    await page.goto('/generate');
    await expect(page.getByRole('heading', { name: 'AI Generation' })).toBeVisible();

    // Tab triggers — text hidden on small screens, use tab role
    const tabs = page.getByRole('tab');
    await expect(tabs).toHaveCount(3);
  });

  test('quick tab shows form fields', async ({ page }) => {
    await page.goto('/generate');
    await expect(page.getByText('Quick Generate')).toBeVisible();
    await expect(page.getByText('Node Type')).toBeVisible();
    await expect(page.getByText('Biome')).toBeVisible();
    await expect(page.getByText('Node Name')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Generate Node' })).toBeVisible();
  });

  test('name validation shows error', async ({ page }) => {
    await page.goto('/generate');

    // Clear the name field and submit
    const nameInput = page.getByPlaceholder('Enter a name for this node...');
    await nameInput.clear();
    await page.getByRole('button', { name: 'Generate Node' }).click();

    await expect(page.getByText('Name is required')).toBeVisible();
  });

  test('tab switching works', async ({ page }) => {
    await page.goto('/generate');
    await expect(page.getByText('Quick Generate')).toBeVisible();

    // Click Assisted tab
    await page.getByRole('tab').nth(1).click();
    await expect(page.getByText('Quick Generate')).not.toBeVisible();

    // Click Bulk tab
    await page.getByRole('tab').nth(2).click();
  });
});
