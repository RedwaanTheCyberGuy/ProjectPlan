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
  await page.getByRole("button", { name: /Full Plan/i }).click();

  const firstCard = page.locator(".task-card").first();
  const taskId = await firstCard.getAttribute("data-task-id");
  expect(taskId).toBeTruthy();
  const cardById = () => page.locator(`.task-card[data-task-id="${taskId}"]`).first();

  await firstCard.locator(".move-select").selectOption("In Progress");
  const movedCard = cardById();
  await expect(movedCard.locator(".progress-chip")).toHaveText("In Progress");
  await expect(movedCard.locator(".move-select")).toHaveValue("In Progress");
  const moveSelectWidth = await movedCard.locator(".move-select").evaluate(el => el.getBoundingClientRect().width);
  expect(moveSelectWidth).toBeGreaterThanOrEqual(120);

  await page.reload();

  const sameCard = cardById();
  await expect(sameCard.locator(".progress-chip")).toHaveText("In Progress");
});

test("multiple status moves persist correctly across refreshes", async ({ page }) => {
  await page.route("**/supabase-config.js", async route => {
    await route.fulfill({
      contentType: "application/javascript",
      body: 'window.BEYOND_CODE_SUPABASE = { url: "YOUR_SUPABASE_URL", anonKey: "YOUR_SUPABASE_ANON_KEY" };'
    });
  });

  await page.goto("/");
  await page.getByRole("button", { name: "Seed tasks" }).click();
  await page.getByRole("button", { name: /Full Plan/i }).click();

  const firstCard = page.locator(".task-card").first();
  const taskId = await firstCard.getAttribute("data-task-id");
  expect(taskId).toBeTruthy();

  const cardById = () => page.locator(`.task-card[data-task-id="${taskId}"]`).first();

  await cardById().locator(".move-select").selectOption("Done");
  await expect(cardById().locator(".progress-chip")).toHaveText("Done");
  await page.reload();
  await expect(cardById().locator(".progress-chip")).toHaveText("Done");

  await cardById().locator(".move-select").selectOption("To Do");
  await expect(cardById().locator(".progress-chip")).toHaveText("To Do");
  await page.reload();
  await expect(cardById().locator(".progress-chip")).toHaveText("To Do");
});
