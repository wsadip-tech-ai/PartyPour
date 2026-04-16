import { test, expect } from '@playwright/test'

/**
 * Navigation tests.
 *
 * These tests verify that the sidebar renders correctly and that each
 * main route loads without a hard crash. They require an authenticated
 * session. If AUTH_STORAGE_STATE is set they use it; otherwise they
 * attempt to load pages directly (useful when middleware is permissive
 * in dev mode or when running against a seeded test environment).
 *
 * To generate a storage state file:
 *   1. Run `npx playwright codegen http://localhost:3000/login`
 *   2. Log in manually
 *   3. Save the storage state JSON
 *   4. Set AUTH_STORAGE_STATE=path/to/state.json
 */

const routes = [
  { path: '/dashboard', label: 'Dashboard' },
  { path: '/categories', label: 'Categories' },
  { path: '/products', label: 'Products' },
  { path: '/discounts', label: 'Discounts' },
  { path: '/orders', label: 'Orders' },
  { path: '/customers', label: 'Customers' },
  { path: '/analytics', label: 'Analytics' },
  { path: '/equipment', label: 'Equipment' },
  { path: '/estimation-rules', label: 'Estimation Rules' },
  { path: '/company-docs', label: 'AI Knowledge Base' },
]

test.describe('Sidebar Navigation', () => {
  test('sidebar renders with all navigation links', async ({ page }) => {
    await page.goto('/dashboard')
    await page.waitForLoadState('networkidle')

    // If redirected to login, skip sidebar checks
    if (page.url().includes('/login')) {
      test.skip(true, 'Not authenticated — skipping sidebar test')
    }

    // Sidebar brand
    await expect(page.getByText('PartyPour')).toBeVisible()
    await expect(page.getByText('Admin Portal')).toBeVisible()

    // Check each nav link is present
    for (const route of routes) {
      const link = page.getByRole('link', { name: route.label })
      await expect(link).toBeVisible()
    }

    // Sign Out button
    await expect(page.getByRole('button', { name: /sign out/i })).toBeVisible()
  })
})

test.describe('Route Loading', () => {
  for (const route of routes) {
    test(`${route.label} (${route.path}) loads without errors`, async ({ page }) => {
      // Listen for console errors
      const consoleErrors: string[] = []
      page.on('console', (msg) => {
        if (msg.type() === 'error') consoleErrors.push(msg.text())
      })

      const response = await page.goto(route.path)
      await page.waitForLoadState('networkidle')

      // If redirected to login, that is acceptable — not a crash
      if (page.url().includes('/login')) {
        expect(response?.status()).toBeLessThan(500)
        return
      }

      // Page should return a successful status
      expect(response?.status()).toBeLessThan(500)

      // No "Application error" or Next.js error overlay
      const body = await page.textContent('body')
      expect(body).not.toContain('Application error')
      expect(body).not.toContain('Internal Server Error')

      // Filter out benign Supabase/fetch errors that happen without real data
      const criticalErrors = consoleErrors.filter(
        (e) =>
          !e.includes('supabase') &&
          !e.includes('Failed to fetch') &&
          !e.includes('NetworkError') &&
          !e.includes('ERR_CONNECTION')
      )
      // Allow a few non-critical console errors, but flag if excessive
      expect(criticalErrors.length).toBeLessThan(5)
    })
  }
})
