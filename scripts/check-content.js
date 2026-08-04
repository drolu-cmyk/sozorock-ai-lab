#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const exists = p => fs.existsSync(path.join(root, p));
const failures = [];
const html = read('site/index.html');
const js = read('site/assets/js/main.js');

const requiredCopy = [
  'Before we automate,',
  'we decide.',
  'A practical lab for learning what AI should do, what it should not do, and how to prove the difference.',
  'The point is not to know every tool.',
  'It is to make better decisions when the tools change.',
  'Frame the problem',
  'Test the risk',
  'Leave a record',
  'Choose your starting point',
  'Learn for yourself',
  'Equip a team',
  'Train the trainers',
  'Visit the Foundation website'
];
for (const text of requiredCopy) if (!html.includes(text)) failures.push(`Homepage missing approved copy: ${text}`);

const forbidden = [
  /class="(?:steps|step|card|cards|metric|metrics|dashboard)\b/i,
  /Microsoft|Google\.org|OpenAI Academy|AWS for nonprofits|NCR Foundation/i,
  /guaranteed (?:outcome|funding|placement)|certified|accredited/i,
  /unlock your potential|transform your future|revolutionize|game[- ]changer|supercharge/i,
  /SozoRock Health|SozoRock Consulting|SozoRock Technology/i,
  /Day\s+\d+\s+of\s+\d+/i,
  /\b\d{2,}\+\s+(?:learners|workflows|hours)/i,
  /(?:linear-gradient|radial-gradient|conic-gradient)\(/i
];
for (const pattern of forbidden) if (pattern.test(html) || pattern.test(read('site/assets/css/option-3.css'))) failures.push(`Homepage contains prohibited or unsupported content: ${pattern}`);

const legalPages = ['privacy','terms','cookies','acceptable-use','responsible-ai','accessibility','nondiscrimination','data-rights','security','copyright','media-consent','grievances'];
for (const slug of legalPages) {
  const file = `site/${slug}/index.html`;
  if (!exists(file)) failures.push(`Missing legal page: ${file}`);
  else if (read(file).length < 2500) failures.push(`Legal page is unexpectedly thin: ${file}`);
}

const assets = [
  'site/assets/css/styles.css','site/assets/css/option-3.css','site/assets/js/main.js','site/assets/img/sozorock-ai-lab-logo.svg',
  'site/assets/img/option-3-lab.svg','site/assets/img/option-3-canvas.svg','site/favicon.svg',
  'site/apple-touch-icon.png','site/site.webmanifest','site/404.html'
];
for (const asset of assets) if (!exists(asset)) failures.push(`Missing required asset: ${asset}`);

const formFields = ['firstName','lastName','email','region','roleOrOrganization','preferredFormat','technicalExperience','build','sensitiveData','accessNeeds','consent'];
for (const field of formFields) if (!html.includes(`name="${field}"`)) failures.push(`Missing application field: ${field}`);
if (!js.includes("fetch('/api/applications/start'")) failures.push('Application endpoint is missing from main.js.');
if (!js.includes('formStartedAt')) failures.push('Form timing signal is missing.');
if (!html.includes('aria-live="polite"')) failures.push('Accessible form status region is missing.');
if (!html.includes('Do not submit private customer, patient, student, employee, financial, legal, or account information.')) failures.push('Sensitive-information warning is missing.');
if (!html.includes('https://www.sozorockfoundation.org/')) failures.push('Foundation website link is missing.');

const htmlFiles = [];
(function walk(dir) {
  for (const entry of fs.readdirSync(dir, {withFileTypes:true})) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.name.endsWith('.html')) htmlFiles.push(full);
  }
})(path.join(root, 'site'));
for (const file of htmlFiles) {
  const source = fs.readFileSync(file, 'utf8');
  const page = path.relative(path.join(root, 'site'), file);
  const hrefs = [...source.matchAll(/href="(\/[^"?#]*)(?:[?#][^"]*)?"/g)].map(m => m[1]);
  for (const href of new Set(hrefs)) {
    if (href === '/' || href.startsWith('/api/')) continue;
    const rel = href.endsWith('/') ? `${href.slice(1)}index.html` : href.slice(1);
    if (!exists(`site/${rel}`)) failures.push(`${page}: broken internal link target ${href}`);
  }
}

if (failures.length) {
  console.error(`Content checks failed (${failures.length}):\n- ${failures.join('\n- ')}`);
  process.exit(1);
}
console.log(`Content checks passed: approved homepage, ${legalPages.length} policy pages, form, assets, and internal links.`);
