const { test, expect } = require("@playwright/test");

test("moving a card persists after refresh in local mode", async ({ page }) => {
  await page.route("**/supabase-config.js", async route => {
    await route.fulfill({
      contentType: "application/javascript",
      body: 'window.BEYOND_CODE_SUPABASE = { url: "YOUR_SUPABASE_URL", anonKey: "YOUR_SUPABASE_ANON_KEY" };'
    });
  });

  await page.goto("/");
  await page.getByRole("button", { name: "Seed tasks" }).click();

  const firstCard = page.locator(".task-card").first();
  const cardTitle = (await firstCard.locator(".task-title").textContent())?.trim();
  expect(cardTitle).toBeTruthy();

  await firstCard.locator(".move-select").selectOption("In Progress");
  const movedCard = page.locator(".task-card", {
    has: page.locator(".task-title", { hasText: cardTitle })
  }).first();
  await expect(movedCard.locator(".progress-chip")).toHaveText("In Progress");

  await page.reload();

  const sameCard = page.locator(".task-card", {
    has: page.locator(".task-title", { hasText: cardTitle })
  }).first();
  await expect(sameCard.locator(".progress-chip")).toHaveText("In Progress");
});
