import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const outputRoot = new URL("../pages-dist/", import.meta.url);

test("exports the Rally landing page for the repository base path", async () => {
  const html = await readFile(new URL("index.html", outputRoot), "utf8");

  assert.match(html, /<title>Rally — Your badminton rating<\/title>/i);
  assert.match(html, /Every player/);
  assert.match(html, /deserves a/);
  assert.match(html, /Rally AI Coach/);
  assert.match(html, /Skill DNA/);
  assert.doesNotMatch(html, /codex-preview|Your site is taking shape/i);
  assert.match(html, /https:\/\/davidgarg20\.github\.io\/rally\/og\.png/);

  const localAssets = [
    ...html.matchAll(/(?:src|href)="(\/rally\/[^"#?]+)"/g),
  ].map(([, asset]) => asset);
  assert.ok(localAssets.length > 0);

  for (const asset of new Set(localAssets)) {
    await access(new URL(asset.slice("/rally/".length), outputRoot));
  }
});

test("includes the GitHub Pages fallback and Jekyll bypass", async () => {
  const [indexHtml, fallbackHtml] = await Promise.all([
    readFile(new URL("index.html", outputRoot), "utf8"),
    readFile(new URL("404.html", outputRoot), "utf8"),
    access(new URL(".nojekyll", outputRoot)),
  ]);

  assert.equal(fallbackHtml, indexHtml);
});
