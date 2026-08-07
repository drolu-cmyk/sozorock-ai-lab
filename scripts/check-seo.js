#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const site = path.join(root, 'site');
const failures = [];
const pages = [];
function walk(dir) {
  for (const e of fs.readdirSync(dir, {withFileTypes:true})) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name === 'index.html' || e.name === '404.html') pages.push(p);
  }
}
walk(site);
const titles = new Map();
for (const file of pages) {
  const html = fs.readFileSync(file,'utf8');
  const rel = path.relative(site,file);
  const is404 = rel === '404.html';
  const title = html.match(/<title>([^<]+)<\/title>/i)?.[1]?.trim();
  if (!title) failures.push(`${rel}: missing title`);
  else if (!is404 && (title.length < 20 || title.length > 65)) failures.push(`${rel}: title length ${title.length} is outside 20-65 characters`);
  else if (!is404 && titles.has(title)) failures.push(`${rel}: duplicate title with ${titles.get(title)}`);
  else titles.set(title, rel);
  const description = html.match(/<meta name="description" content="([^"]+)"/i)?.[1]?.trim();
  if (!description) failures.push(`${rel}: missing meta description`);
  else if (!is404 && (description.length < 70 || description.length > 180)) failures.push(`${rel}: description length ${description.length} is outside 70-180 characters`);
  if (is404) {
    if (!/name="robots" content="noindex,follow"/i.test(html)) failures.push('404.html: must be noindex,follow');
    continue;
  }
  const required = [
    /<link rel="canonical" href="https:\/\/ai-lab\.sozorockfoundation\.org\//i,
    /property="og:type"/i,/property="og:title"/i,/property="og:description"/i,/property="og:url"/i,
    /name="twitter:card" content="summary(?:_large_image)?"/i,/name="twitter:title"/i,/name="twitter:description"/i,
    /type="application\/ld\+json"/i
  ];
  for (const r of required) if (!r.test(html)) failures.push(`${rel}: missing SEO requirement ${r}`);
  if ((html.match(/<h1[\s>]/gi)||[]).length !== 1) failures.push(`${rel}: must have exactly one h1`);
  for (const match of html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/gi)) {
    try { JSON.parse(match[1]); } catch (e) { failures.push(`${rel}: invalid JSON-LD (${e.message})`); }
  }
}
const sitemap = fs.readFileSync(path.join(site,'sitemap.xml'),'utf8');
const slugs = ['curriculum','organizations','privacy','terms','cookies','acceptable-use','responsible-ai','accessibility','nondiscrimination','data-rights','security','copyright','media-consent','grievances'];
for (const slug of slugs) if (!sitemap.includes(`<loc>https://ai-lab.sozorockfoundation.org/${slug}/</loc>`)) failures.push(`sitemap.xml: missing ${slug}`);
if (!sitemap.includes('<lastmod>2026-08-07</lastmod>')) failures.push('sitemap.xml: missing current lastmod');
const robots = fs.readFileSync(path.join(site,'robots.txt'),'utf8');
if (!robots.includes('Disallow: /api/')) failures.push('robots.txt: API route must be excluded');
if (!robots.includes('Sitemap: https://ai-lab.sozorockfoundation.org/sitemap.xml')) failures.push('robots.txt: missing canonical sitemap');
const manifest = JSON.parse(fs.readFileSync(path.join(site,'site.webmanifest'),'utf8'));
if (manifest.name !== 'SozoRock AI Lab' || manifest.id !== '/' || manifest.start_url !== '/' || !Array.isArray(manifest.icons) || manifest.icons.length < 2) failures.push('site.webmanifest: incomplete identity or icons');
if (failures.length) { console.error(`SEO checks failed (${failures.length}):\n- ${failures.join('\n- ')}`); process.exit(1); }
console.log(`SEO checks passed for ${pages.length - 1} indexable pages plus 404, sitemap, robots, schema, sharing metadata, and manifest.`);
