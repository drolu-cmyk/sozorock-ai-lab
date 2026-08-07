#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const exists = p => fs.existsSync(path.join(root, p));
const failures = [];
const html = read('site/index.html');
const curriculum = read('site/curriculum/index.html');
const js = read('site/assets/js/main.js');

const requiredHomepageCopy = [
  'Practical AI skills for work and community life.',
  'SozoRock AI Lab is a no-cost education program of The SozoRock Foundation.',
  'We help adults and community organizations learn how to use everyday AI tools safely, critically, and productively.',
  'No technical background is required.',
  'Who the Lab serves',
  'What participants learn',
  'How training works',
  'What we measure',
  'For community organizations',
  'Program results will be published as evidence becomes available.',
  'Applications and expressions of interest are reviewed on a rolling basis.'
];
for (const text of requiredHomepageCopy) if (!html.includes(text)) failures.push(`Homepage missing approved copy: ${text}`);

const forbiddenPublicPatterns = [
  /Before we automate/i,
  /AI Capability Lab/i,
  /Day\s+\d+\s+of\s+\d+/i,
  /context engineering/i,
  /context pack/i,
  /evidence saved/i,
  /program outcome/i,
  /capstone defense/i,
  /\bGRC\b/i,
  /SozoRock Meridian|Meridian/i,
  /unlock your potential|transform your future|revolutionize|game[- ]changer|supercharge/i
];
for (const pattern of forbiddenPublicPatterns) {
  if (pattern.test(html) || pattern.test(curriculum)) failures.push(`Public program pages contain removed product/AI pattern: ${pattern}`);
}

const legalPages = ['privacy','terms','cookies','acceptable-use','responsible-ai','accessibility','nondiscrimination','data-rights','security','copyright','media-consent','grievances'];
for (const slug of legalPages) {
  const file = `site/${slug}/index.html`;
  if (!exists(file)) failures.push(`Missing legal page: ${file}`);
  else {
    const source = read(file);
    if (source.length < 2500) failures.push(`Legal page is unexpectedly thin: ${file}`);
    if (source.includes('AI Capability Lab')) failures.push(`${slug}: old program identity remains`);
    if (source.includes('Security or AI incident')) failures.push(`${slug}: old incident language remains`);
    if (!source.includes('SozoRock AI Lab')) failures.push(`${slug}: AI Lab identity is missing`);
  }
}

const formFields = ['firstName','lastName','email','region','roleOrOrganization','preferredFormat','technicalExperience','build','sensitiveData','accessNeeds','consent'];
for (const field of formFields) if (!html.includes(`name="${field}"`)) failures.push(`Missing application field: ${field}`);
if (!js.includes("fetch('/api/applications/start'")) failures.push('Application endpoint is missing from main.js.');
if (!js.includes('formStartedAt')) failures.push('Form timing signal is missing.');
if (!html.includes('aria-live="polite"')) failures.push('Accessible form status region is missing.');
if (!html.includes('Do not submit private customer, patient, student, employee, financial, legal, or account information.')) failures.push('Sensitive-information warning is missing.');
if (!html.includes('https://www.sozorockfoundation.org/')) failures.push('Foundation website link is missing.');
if (!curriculum.includes('Core learning areas') || !curriculum.includes('For community partners')) failures.push('Curriculum does not match the approved community-training direction.');

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
  if (/SozoRock Meridian|Meridian/i.test(source)) failures.push(`${page}: Meridian reference remains public`);
  if (source.includes('AI Capability Lab')) failures.push(`${page}: AI Capability Lab reference remains public`);
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
console.log(`Content checks passed: approved nonprofit homepage, simplified curriculum, ${legalPages.length} policy pages, application form, and internal links.`);
