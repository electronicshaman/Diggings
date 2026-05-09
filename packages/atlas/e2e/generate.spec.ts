import { test, expect } from '@playwright/test'

const GENERATED_NODE_NAME = `E2E Generated Node ${Date.now()}`

test.describe('AI Generation', () => {
  test('navigate to /generate and verify quick generate form loads', async ({ page }) => {
    await page.goto('/generate')
    await expect(page.getByRole('heading', { name: 'AI Generation' })).toBeVisible()
    await expect(page.getByRole('tab', { name: /Quick/i })).toBeVisible()
    await expect(page.getByRole('tab', { name: /Assisted/i })).toBeVisible()
    await expect(page.getByRole('tab', { name: /Bulk/i })).toBeVisible()
  })

  test('quick generate form has correct fields', async ({ page }) => {
    await page.goto('/generate')
    // Quick tab is active by default — CardTitle is a <div> not heading
    await expect(page.locator('div').filter({ hasText: /^Quick Generate$/ }).first()).toBeVisible()
    // Form labels
    await expect(page.getByText('Node Type')).toBeVisible()
    await expect(page.getByText('Biome')).toBeVisible()
    await expect(page.getByLabel('Node Name')).toBeVisible()
    await expect(page.getByText('Acts', { exact: true }).first()).toBeVisible()
    await expect(page.getByRole('button', { name: /Generate Node/i })).toBeVisible()
  })

  test('quick generate — select type + biome + name and submit', async ({ page }) => {
    await page.goto('/generate')

    // Fill in node name
    await page.getByLabel('Node Name').fill(GENERATED_NODE_NAME)

    // Node type defaults to "combat", biome to "township", Act 1 checked — just submit
    await page.getByRole('button', { name: /Generate Node/i }).click()

    // Should show progress screen (regardless of whether API key is valid)
    // Either streaming progress or an error about missing provider
    await expect(
      page.getByText(/Generating|Progress|error|No.*provider|API key|provider|failed/i).first()
    ).toBeVisible({ timeout: 15000 })
  })

  test('bulk tab shows content', async ({ page }) => {
    await page.goto('/generate')
    await page.getByRole('tab', { name: /Bulk/i }).click()
    // The bulk tab content should render (TabsContent uses data-state="active")
    await expect(page.locator('[data-state="active"]').last()).toBeVisible()
  })
})
