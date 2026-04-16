import { chromium } from 'playwright'

const BASE = 'https://adminportal-five-gamma.vercel.app'

;(async () => {
  const browser = await chromium.launch({ headless: true })
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } })

  // Login
  console.log('1. Login')
  await page.goto(`${BASE}/login`)
  await page.fill('input[type="email"]', 'admin@raksichaiyo.com')
  await page.fill('input[type="password"]', 'Admin@123456')
  await page.click('button[type="submit"]')
  await page.waitForURL('**/dashboard', { timeout: 15000 })

  // Funnel tab
  console.log('2. Analytics — Funnel')
  await page.goto(`${BASE}/analytics`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-01-funnel.png', fullPage: true })

  // Users tab
  console.log('3. Analytics — Users')
  await page.goto(`${BASE}/analytics/users`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-02-users.png', fullPage: true })

  // Activity tab
  console.log('4. Analytics — Activity')
  await page.goto(`${BASE}/analytics/activity`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-03-activity.png', fullPage: true })

  // Customers page (updated)
  console.log('5. Customers — with wizard step')
  await page.goto(`${BASE}/customers`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-04-customers.png', fullPage: true })

  await browser.close()
  console.log('Done!')
})()
