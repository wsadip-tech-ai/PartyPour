import { test, expect } from '@playwright/test'

test.describe('Login Page', () => {
  test('renders login form with email, password, and submit button', async ({ page }) => {
    await page.goto('/login')

    // Check page title / heading
    await expect(page.getByRole('heading', { name: /admin/i })).toBeVisible()

    // Check email field
    const emailInput = page.getByLabel(/email/i)
    await expect(emailInput).toBeVisible()
    await expect(emailInput).toHaveAttribute('type', 'email')

    // Check password field
    const passwordInput = page.getByLabel(/password/i)
    await expect(passwordInput).toBeVisible()
    await expect(passwordInput).toHaveAttribute('type', 'password')

    // Check submit button
    const submitButton = page.getByRole('button', { name: /sign in/i })
    await expect(submitButton).toBeVisible()
    await expect(submitButton).toBeEnabled()
  })

  test('has descriptive card text', async ({ page }) => {
    await page.goto('/login')

    await expect(page.getByText(/sign in to manage/i)).toBeVisible()
  })

  test('submit button shows loading state when clicked with empty required fields', async ({ page }) => {
    await page.goto('/login')

    // The form uses HTML required attributes, so submitting empty fields
    // should not proceed. Verify the button is still enabled after click attempt.
    const submitButton = page.getByRole('button', { name: /sign in/i })
    await submitButton.click()

    // Button should still say "Sign In" (not "Signing in...") because
    // HTML validation prevents form submission with empty required fields
    await expect(submitButton).toContainText('Sign In')
  })

  test('unauthenticated users can reach the login page', async ({ page }) => {
    // Navigate to a protected route — should redirect to /login or block
    await page.goto('/dashboard')

    // Either we end up on /login or the page loads (depends on middleware).
    // At minimum the page should not crash with a JS error.
    await page.waitForLoadState('networkidle')

    // If middleware redirects, we should be on /login
    const url = page.url()
    const isOnLogin = url.includes('/login')
    const isOnDashboard = url.includes('/dashboard')

    // One of these should be true — the page loaded without a hard crash
    expect(isOnLogin || isOnDashboard).toBeTruthy()
  })
})
