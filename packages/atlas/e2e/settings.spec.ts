import { test, expect } from '@playwright/test'
import { request } from '@playwright/test'

const PROVIDER_NAME = `Anthropic E2E ${Date.now()}`
const PROVIDER_NAME_UPDATED = `${PROVIDER_NAME} Updated`

test.describe('Settings — LLM Providers', () => {
  // Clean up any leftover E2E test providers before the suite
  test.beforeAll(async () => {
    const context = await request.newContext({ baseURL: 'http://localhost:3000' })
    const res = await context.get('/api/llm/providers')
    const providers = await res.json() as Array<{ id: number; name: string }>
    for (const p of providers) {
      if (p.name.startsWith('Anthropic E2E')) {
        await context.delete(`/api/llm/providers/${p.id}`)
      }
    }
    await context.dispose()
  })

  test('settings page loads with provider and generation sections', async ({ page }) => {
    await page.goto('/settings')
    await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible()
    // CardTitle renders as <div> not heading; use the exact div text
    await expect(page.locator('div').filter({ hasText: /^LLM Providers$/ }).first()).toBeVisible()
    await expect(page.locator('div').filter({ hasText: /^Generation Settings$/ }).first()).toBeVisible()
    await expect(page.getByRole('button', { name: /Add Provider/i })).toBeVisible()
  })

  test('open Add Provider dialog and fill in Anthropic provider', async ({ page }) => {
    await page.goto('/settings')
    await page.getByRole('button', { name: /Add Provider/i }).click()

    await expect(page.getByRole('dialog')).toBeVisible()

    await page.getByLabel('Name *').fill(PROVIDER_NAME)

    // Provider type select inside dialog
    await page.getByRole('dialog').getByRole('combobox').click()
    await page.getByRole('option', { name: 'Anthropic' }).click()

    await page.getByLabel('Model *').fill('claude-sonnet-4-6')
    await page.getByLabel(/API Key/i).fill('sk-ant-test-placeholder')
    await page.getByLabel('Set as active provider').click()
    await page.getByRole('button', { name: /Create Provider/i }).click()

    await expect(page.getByRole('dialog')).not.toBeVisible({ timeout: 5000 })
    await expect(page.getByRole('cell', { name: PROVIDER_NAME })).toBeVisible()
  })

  test('edit existing provider', async ({ page }) => {
    await page.goto('/settings')
    await expect(page.getByRole('cell', { name: PROVIDER_NAME })).toBeVisible({ timeout: 10000 })

    // Find the row for our provider and click its edit button
    const row = page.getByRole('row', { name: new RegExp(PROVIDER_NAME) })
    await row.getByTitle('Edit provider').click()

    await expect(page.getByRole('dialog')).toBeVisible()

    const nameInput = page.getByLabel('Name *')
    await nameInput.click({ clickCount: 3 })
    await nameInput.fill(PROVIDER_NAME_UPDATED)
    await page.getByRole('button', { name: /Update Provider/i }).click()

    await expect(page.getByRole('dialog')).not.toBeVisible({ timeout: 5000 })
    await expect(page.getByRole('cell', { name: PROVIDER_NAME_UPDATED })).toBeVisible()
  })

  test('delete test provider', async ({ page }) => {
    await page.goto('/settings')
    await expect(page.getByRole('cell', { name: PROVIDER_NAME_UPDATED })).toBeVisible({ timeout: 10000 })

    // Accept the browser confirm dialog
    page.on('dialog', (dialog) => dialog.accept())

    const row = page.getByRole('row', { name: new RegExp(PROVIDER_NAME_UPDATED) })
    await row.getByTitle('Delete provider').click()

    await expect(page.getByRole('cell', { name: PROVIDER_NAME_UPDATED })).not.toBeVisible({ timeout: 5000 })
  })
})
