import { test, expect } from '@playwright/test'

test.describe('Analytics Users & Notifications', () => {
  test('analytics users page loads', async ({ page }) => {
    await page.goto('/analytics/users')
    await page.waitForLoadState('networkidle')

    if (page.url().includes('/login')) {
      test.skip(true, 'Not authenticated — skipping notifications test')
    }

    // The page should render a search input and segment filter
    await expect(page.getByPlaceholder(/search name or email/i)).toBeVisible()
  })

  test('analytics users page has user table with expected columns', async ({ page }) => {
    await page.goto('/analytics/users')
    await page.waitForLoadState('networkidle')

    if (page.url().includes('/login')) {
      test.skip(true, 'Not authenticated — skipping notifications test')
    }

    // Table headers
    await expect(page.getByRole('columnheader', { name: /customer/i })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: /segment/i })).toBeVisible()
    await expect(page.getByRole('columnheader', { name: /orders/i })).toBeVisible()
  })

  test('send notification button appears when users are selected', async ({ page }) => {
    await page.goto('/analytics/users')
    await page.waitForLoadState('networkidle')

    if (page.url().includes('/login')) {
      test.skip(true, 'Not authenticated — skipping notifications test')
    }

    // Initially, the "Send Notification" button should NOT be visible
    // (it only appears when selectedIds.size > 0)
    await expect(page.getByRole('button', { name: /send notification/i })).not.toBeVisible()

    // If there are users in the table, select all via the header checkbox
    const headerCheckbox = page.locator('thead input[type="checkbox"]')
    const isVisible = await headerCheckbox.isVisible()
    if (isVisible) {
      await headerCheckbox.check()

      // Check if any rows exist — if so, button should appear
      const rowCount = await page.locator('tbody tr').count()
      const hasNoUsersMessage = await page.getByText(/no users found/i).isVisible()

      if (rowCount > 0 && !hasNoUsersMessage) {
        await expect(page.getByRole('button', { name: /send notification/i })).toBeVisible()
      }
    }
  })
})
