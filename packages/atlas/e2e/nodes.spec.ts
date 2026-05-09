import { test, expect } from '@playwright/test'

const TEST_NODE_NAME = `E2E Test Combat Node ${Date.now()}`
const UPDATED_NODE_NAME = `${TEST_NODE_NAME} (edited)`

// Shared state for node ID across tests
let createdNodeId: string

test.describe('Node CRUD', () => {
  test('node list page loads at /', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('heading', { name: 'Nodes' })).toBeVisible()
    await expect(page.getByRole('main').getByRole('link', { name: /Create Node/i })).toBeVisible()
  })

  test('create a combat node via wizard and verify it appears in list', async ({ page }) => {
    await page.goto('/nodes/create')

    // Step 0: Select type — click the "Combat" card
    await expect(page.getByRole('heading', { name: 'Select Node Type' })).toBeVisible()
    await page.getByRole('heading', { name: 'Combat' }).click()

    // Step 1: Base fields
    await expect(page.getByRole('heading', { name: 'Base Node Properties' })).toBeVisible()
    await page.getByLabel('Name *').fill(TEST_NODE_NAME)

    // Select biome via the placeholder text
    await page.getByText('Select biome').click()
    await page.getByRole('option', { name: 'Township' }).click()

    // Select Act 1 (label rendered as "1: Arrival")
    await page.getByLabel('1: Arrival').click()

    await page.getByRole('button', { name: 'Next' }).click()

    // Step 2: Type-specific (Combat) — select at least one enemy type
    await expect(page.getByRole('heading', { name: /Combat Properties/i })).toBeVisible()
    // Wait for enemy type checkboxes to load from API, then check the first one
    await page.waitForSelector('text=drunk_miner', { timeout: 10000 })
    await page.getByText('drunk_miner').locator('..').getByRole('checkbox').click()
    await page.getByRole('button', { name: 'Next' }).click()

    // Step 3: Eligibility — just advance
    await page.getByRole('button', { name: 'Next' }).click()

    // Step 4: Review & Create
    await expect(page.getByRole('heading', { name: 'Review & Create' })).toBeVisible()
    await expect(page.getByText(TEST_NODE_NAME)).toBeVisible()
    await page.getByRole('button', { name: 'Create Node' }).click()

    // Should redirect to node detail (not /nodes/create)
    await page.waitForURL(/\/nodes\/(?!create).+/, { timeout: 10000 })
    createdNodeId = page.url().split('/nodes/')[1]
    await expect(page.getByRole('heading', { level: 1 })).toContainText(TEST_NODE_NAME)
  })

  test('node appears in list after creation', async ({ page }) => {
    await page.goto('/nodes')
    await expect(page.getByText(TEST_NODE_NAME)).toBeVisible({ timeout: 10000 })
  })

  test('view node detail page', async ({ page }) => {
    await page.goto('/nodes')
    await page.waitForSelector(`text=${TEST_NODE_NAME}`)
    await page.getByText(TEST_NODE_NAME).first().click()

    await expect(page).toHaveURL(/\/nodes\/.+/)
    await expect(page.getByRole('heading', { level: 1 })).toContainText(TEST_NODE_NAME)
    await expect(page.getByRole('tab', { name: 'Metadata' })).toBeVisible()
    await expect(page.getByRole('tab', { name: 'Content' })).toBeVisible()
  })

  test('edit node and save', async ({ page }) => {
    await page.goto('/nodes')
    await page.waitForSelector(`text=${TEST_NODE_NAME}`)
    await page.getByText(TEST_NODE_NAME).first().click()

    await expect(page).toHaveURL(/\/nodes\/.+/)
    await page.getByRole('link', { name: /Edit/i }).click()
    await expect(page).toHaveURL(/\/nodes\/.+\/edit/)

    // Edit page is a single form (no wizard steps)
    await expect(page.getByRole('heading', { name: 'Edit Node' })).toBeVisible()

    // Update name — pressSequentially fires real keyboard events for React Hook Form dirty detection
    const nameInput = page.getByLabel('Name *')
    await nameInput.click()
    await page.keyboard.press('ControlOrMeta+a')
    await nameInput.pressSequentially(UPDATED_NODE_NAME)

    // Wait for Save Changes button to become enabled (isDirty = true)
    await expect(page.getByRole('button', { name: 'Save Changes' })).toBeEnabled({ timeout: 5000 })
    await page.getByRole('button', { name: 'Save Changes' }).click()

    // After save, navigates back to detail page (no /edit in URL)
    await page.waitForURL(/\/nodes\/[^/]+$/, { timeout: 10000 })
    await expect(page.getByRole('heading', { level: 1 })).toContainText(UPDATED_NODE_NAME)
  })

  test('delete node', async ({ page }) => {
    await page.goto('/nodes')
    await page.waitForSelector(`text=${UPDATED_NODE_NAME}`)
    await page.getByText(UPDATED_NODE_NAME).first().click()

    await expect(page).toHaveURL(/\/nodes\/.+/)
    // Click the destructive Delete button in the header actions area
    await page.getByRole('button', { name: /Delete/i }).first().click()

    // Confirm deletion dialog
    await expect(page.getByRole('dialog')).toBeVisible()
    await page.getByRole('dialog').getByRole('button', { name: 'Delete' }).click()

    // Should redirect to node list
    await expect(page).toHaveURL(/\/nodes$|^\/$/)
    await expect(page.getByText(UPDATED_NODE_NAME)).not.toBeVisible()
  })
})
