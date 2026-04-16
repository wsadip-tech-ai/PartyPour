import { test, expect } from '@playwright/test'

test.describe('Dashboard Page', () => {
  test('dashboard loads and shows heading', async ({ page }) => {
    await page.goto('/dashboard')
    await page.waitForLoadState('networkidle')

    // If redirected to login, skip dashboard-specific checks
    if (page.url().includes('/login')) {
      test.skip(true, 'Not authenticated — skipping dashboard test')
    }

    // Main heading
    await expect(page.getByRole('heading', { name: /dashboard/i })).toBeVisible()
  })

  test('dashboard shows stat cards', async ({ page }) => {
    await page.goto('/dashboard')
    await page.waitForLoadState('networkidle')

    if (page.url().includes('/login')) {
      test.skip(true, 'Not authenticated — skipping dashboard test')
    }

    // The dashboard renders 4 stat cards: Total Orders, Products, Revenue, Pending Orders
    const expectedCards = ['Total Orders', 'Products', 'Revenue', 'Pending Orders']
    for (const title of expectedCards) {
      await expect(page.getByText(title)).toBeVisible()
    }
  })

  test('dashboard page does not show error state', async ({ page }) => {
    const response = await page.goto('/dashboard')
    await page.waitForLoadState('networkidle')

    if (page.url().includes('/login')) {
      // Redirect to login is fine — not an error
      expect(response?.status()).toBeLessThan(500)
      return
    }

    expect(response?.status()).toBeLessThan(500)

    const body = await page.textContent('body')
    expect(body).not.toContain('Application error')
    expect(body).not.toContain('Internal Server Error')
  })
})
