import { chromium } from 'playwright';

const BASE = 'https://adminportal-five-gamma.vercel.app';

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  // 1. Login
  console.log('--- Navigating to login ---');
  await page.goto(`${BASE}/login`);
  await page.screenshot({ path: 'screenshots/01-login.png', fullPage: true });
  console.log('Screenshot: 01-login.png');

  await page.fill('input[type="email"]', 'admin@raksichaiyo.com');
  await page.fill('input[type="password"]', 'Admin@123456');
  await page.click('button[type="submit"]');
  await page.waitForURL('**/dashboard', { timeout: 15000 });
  await page.screenshot({ path: 'screenshots/02-dashboard.png', fullPage: true });
  console.log('Screenshot: 02-dashboard.png');

  // 2. Orders list
  console.log('--- Navigating to orders ---');
  await page.click('a[href="/orders"]');
  await page.waitForURL('**/orders');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'screenshots/03-orders-list.png', fullPage: true });
  console.log('Screenshot: 03-orders-list.png');

  // 3. Try "All Statuses" filter
  await page.click('button:has-text("Pending")');
  await page.waitForTimeout(500);
  const allOption = page.locator('[role="option"]:has-text("All Statuses")');
  if (await allOption.isVisible()) {
    await allOption.click();
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'screenshots/04-orders-all.png', fullPage: true });
    console.log('Screenshot: 04-orders-all.png');
  }

  // 4. Click first order to see detail
  const firstOrderLink = page.locator('a[href^="/orders/"]').first();
  if (await firstOrderLink.isVisible()) {
    await firstOrderLink.click();
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'screenshots/05-order-detail.png', fullPage: true });
    console.log('Screenshot: 05-order-detail.png');
  } else {
    console.log('No order links found on the page');
  }

  // 5. Check products page
  console.log('--- Navigating to products ---');
  await page.goto(`${BASE}/products`);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'screenshots/06-products.png', fullPage: true });
  console.log('Screenshot: 06-products.png');

  await browser.close();
  console.log('--- Done ---');
})();
