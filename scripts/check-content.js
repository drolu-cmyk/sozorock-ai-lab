#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const htmlPath = path.join(root, 'site', 'index.html');
const html = fs.readFileSync(htmlPath, 'utf8');
const failures = [];

const requiredText = [
  'Practical AI participation',
  'Use AI to do real work.',
  'Learn one skill. Build one workflow. Show what changed.',
  'No-cost participation',
  'Learn by solving a real problem.',
  'Start where the work is.',
  'Learn. Build. Save the evidence.',
  'We count demonstrated use, not just attendance.',
  'Fund a cohort. Host a Lab. Provide technology.',
  'Applications are reviewed on a rolling basis.'
];
for (const text of requiredText) {
  if (!html.includes(text)) failures.push(`Missing required content: ${text}`);
}

const forbiddenPatterns = [
  /Applications open for Cohort 02/i,
  /June 2026/i,
  /cohort-02/i,
  /Ship real workflows/i,
  /Any cost, sponsorship, scholarship/i,
  /operational leverage/i,
  /AI-powered future/i
];
for (const pattern of forbiddenPatterns) {
  if (pattern.test(html)) failures.push(`Stale or prohibited copy found: ${pattern}`);
}

const requiredFiles = [
  'site/privacy/index.html',
  'site/accessibility/index.html',
  'site/nondiscrimination/index.html',
  'site/terms/index.html',
  'site/sitemap.xml',
  'site/favicon.ico'
];
for (const relative of requiredFiles) {
  if (!fs.existsSync(path.join(root, relative))) failures.push(`Missing required file: ${relative}`);
}

const requiredFormFields = ['firstName','lastName','email','region','roleOrOrganization','preferredFormat','technicalExperience','build','sensitiveData','accessNeeds','consent'];
for (const name of requiredFormFields) {
  if (!html.includes(`name="${name}"`)) failures.push(`Missing form field: ${name}`);
}

const requiredTrustLinks = ['/privacy','/accessibility','/nondiscrimination','/terms'];
for (const href of requiredTrustLinks) {
  if (!html.includes(`href="${href}"`)) failures.push(`Missing trust link: ${href}`);
}

if (!html.includes('/api/applications/start')) failures.push('Application API endpoint is missing.');
if (!html.includes('rolling-intake')) failures.push('Rolling intake identifier is missing.');
if (!html.includes('application/ld+json')) failures.push('Structured data is missing.');
if (!html.includes('"price":"0"')) failures.push('Structured data must state that participation is no cost.');
if (!html.includes('aria-live="polite"')) failures.push('Accessible form status region is missing.');
if (!html.includes('Report an AI or security incident')) failures.push('AI and security incident reporting link is missing.');
if (!html.includes('not affiliated with, endorsed by, or sponsored by OpenAI')) failures.push('Third-party independence disclaimer is missing.');

if (failures.length) {
  console.error('Content checks failed:\n- ' + failures.join('\n- '));
  process.exit(1);
}
console.log(`Content checks passed (${requiredText.length} required statements, ${requiredFiles.length} required files, ${requiredFormFields.length} form fields).`);
