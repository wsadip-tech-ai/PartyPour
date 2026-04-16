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
  await page.screenshot({ path: 'screenshots/phase1-01-dashboard.png', fullPage: true })
  console.log('  -> Dashboard OK')

  // Orders list
  console.log('2. Orders list')
  await page.click('a[href="/orders"]')
  await page.waitForURL('**/orders')
  await page.waitForTimeout(2000)
  await page.screenshot({ path: 'screenshots/phase1-02-orders-list.png', fullPage: true })
  console.log('  -> Orders list OK')

  // Change filter to All
  await page.click('button:has-text("pending")');
  await page.waitForTimeout(500)
  const allOpt = page.locator('[role="option"]:has-text("All Statuses")')
  if (await allOpt.isVisible()) {
    await allOpt.click()
    await page.waitForTimeout(2000)
  }
  await page.screenshot({ path: 'screenshots/phase1-03-orders-all.png', fullPage: true })
  console.log('  -> Orders all filter OK')

  // Order detail — click View button
  console.log('3. Order detail')
  const viewBtn = page.locator('a[href^="/orders/"] button:has-text("View")').first()
  if (await viewBtn.isVisible()) {
    await viewBtn.click()
    await page.waitForTimeout(3000)
    await page.screenshot({ path: 'screenshots/phase1-04-order-detail.png', fullPage: true })
    console.log('  -> Order detail OK')

    // Dispatch slip
    console.log('4. Dispatch slip')
    const currentUrl = page.url()
    const orderId = currentUrl.split('/orders/')[1]
    await page.goto(`${BASE}/orders/${orderId}/dispatch-slip`)
    await page.waitForTimeout(3000)
    await page.screenshot({ path: 'screenshots/phase1-05-dispatch-slip.png', fullPage: true })
    console.log('  -> Dispatch slip OK')
  }

  // Customers list
  console.log('5. Customers list')
  await page.goto(`${BASE}/customers`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/phase1-06-customers.png', fullPage: true })
  console.log('  -> Customers OK')

  // Customer detail
  console.log('6. Customer detail')
  const customerLink = page.locator('a[href^="/customers/"]').first()
  if (await customerLink.isVisible()) {
    await customerLink.click()
    await page.waitForTimeout(3000)
    await page.screenshot({ path: 'screenshots/phase1-07-customer-detail.png', fullPage: true })
    console.log('  -> Customer detail OK')
  }

  await browser.close()
  console.log('Done! All screenshots in screenshots/')
})()
