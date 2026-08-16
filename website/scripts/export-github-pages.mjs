import { cp, mkdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const clientRoot = path.join(projectRoot, "dist", "client");
const outputRoot = path.join(projectRoot, "pages-dist");
const repositoryBasePath = "/rally/";

await rm(outputRoot, { recursive: true, force: true });
await mkdir(outputRoot, { recursive: true });
await cp(clientRoot, outputRoot, { recursive: true });

const workerUrl = pathToFileURL(path.join(projectRoot, "dist", "server", "index.js"));
workerUrl.searchParams.set("github-pages-export", Date.now().toString());
const { default: worker } = await import(workerUrl.href);

const response = await worker.fetch(
  new Request("https://davidgarg20.github.io/", {
    headers: { accept: "text/html" },
  }),
  {
    ASSETS: {
      fetch: async () => new Response("Not found", { status: 404 }),
    },
  },
  {
    waitUntil() {},
    passThroughOnException() {},
  },
);

if (response.status !== 200) {
  throw new Error(`Static render failed with HTTP ${response.status}`);
}

let html = await response.text();
html = html
  .replaceAll('"/_next/', `"${repositoryBasePath}_next/`)
  .replaceAll('"/favicon.svg"', `"${repositoryBasePath}favicon.svg"`)
  .replaceAll('"/og.png"', `"${repositoryBasePath}og.png"`);

const unprefixedAssets = [...html.matchAll(/(?:src|href)="(\/(?!rally\/)[^"]+)"/g)].map(
  ([, asset]) => asset,
);
if (unprefixedAssets.length > 0) {
  throw new Error(`Found assets outside ${repositoryBasePath}: ${unprefixedAssets.join(", ")}`);
}

await Promise.all([
  writeFile(path.join(outputRoot, "index.html"), html),
  writeFile(path.join(outputRoot, "404.html"), html),
  writeFile(path.join(outputRoot, ".nojekyll"), ""),
]);

console.log(`GitHub Pages export created at ${outputRoot}`);
