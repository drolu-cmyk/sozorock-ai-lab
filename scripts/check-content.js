#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const exists = p => fs.existsSync(path.join(root, p));
const failures = [];
const html = read('site/index.html');
const curriculum = read('site/curriculum/index.html');
const organizations = read('site/organizations/index.html');
const js = read('site/assets/js/main.js');

const requiredHomepageCopy = [
  'Practical AI skills for work and community life.',
  'SozoRock AI Lab is a no-cost, tool-neutral AI literacy and skills program for adults and community organizations.',
  'No technical background required.',
  'Learning in practice',
  'Edward Jones',
  'Capital Property Care',
  'Human judgment stays in control throughout.',
  'Participant story and media shared with consent.',
  'Responsible AI skills',
  'AI workshops and guided learning',
  'Evidence, not hype',
  'For community organizations',
  'Program results will be published as evidence becomes available.',
  'Applications and expressions of interest are reviewed on a rolling basis.'
];
for (const text of requiredHomepageCopy) if (!html.includes(text)) failures.push(`Homepage missing approved campaign copy: ${text}`);

const requiredPositioning = ['tool-neutral','AI literacy','responsible AI','guided practice','community organizations','workforce organizations','libraries'];
for (const term of requiredPositioning) if (!html.toLowerCase().includes(term.toLowerCase())) failures.push(`Homepage missing positioning term: ${term}`);

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
  if (pattern.test(html) || pattern.test(curriculum) || pattern.test(organizations)) failures.push(`Public program pages contain removed product/hype pattern: ${pattern}`);
}
if (/>(?:\s*)0[1-9](?:\s*)</.test(html)) failures.push('Homepage contains numbered visual UI; approved campaign direction is unnumbered.');

for (const [name, source] of [['homepage', html], ['curriculum', curriculum], ['organizations', organizations]]) {
  if (/href="mailto:/i.test(source)) failures.push(`${name}: email-based link remains on a primary program page`);
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
    if (!source.includes('href="/organizations/"')) failures.push(`${slug}: on-site organization route is missing from generated navigation`);
  }
}

const participantFields = ['firstName','lastName','email','region','roleOrOrganization','preferredFormat','technicalExperience','build','sensitiveData','accessNeeds','consent'];
for (const field of participantFields) if (!html.includes(`name="${field}"`)) failures.push(`Missing participant application field: ${field}`);
const organizationFields = ['firstName','lastName','email','roleOrOrganization','region','preferredFormat','organizationType','build','audience','accessNeeds','consent'];
for (const field of organizationFields) if (!organizations.includes(`name="${field}"`)) failures.push(`Missing organization inquiry field: ${field}`);
if (!html.includes('data-application-type="participant-interest"')) failures.push('Homepage form is missing participant application type.');
if (!organizations.includes('data-application-type="organization-interest"')) failures.push('Organization form is missing organization application type.');
if (!js.includes("fetch('/api/applications/start'")) failures.push('Application endpoint is missing from main.js.');
if (!js.includes('formStartedAt')) failures.push('Form timing signal is missing.');
if (!js.includes('applicationType')) failures.push('Application type is not sent by main.js.');
if (js.includes('email contact@sozorockfoundation.org')) failures.push('Form failure state still tells users to email instead of recovering on site.');
if (!html.includes('aria-live="polite"') || !organizations.includes('aria-live="polite"')) failures.push('Accessible form status region is missing.');
if (!html.includes('Do not submit private customer, patient, student, employee, financial, legal, or account information.')) failures.push('Sensitive-information warning is missing.');
if (!html.includes('https://www.sozorockfoundation.org/')) failures.push('Foundation website link is missing.');
if (!html.includes('href="https://www.capitalpropertycare.com/"')) failures.push('Participant project link is missing from the homepage.');
if (!html.includes('1W_xoDe-sK_4e3CBlLE0Gh3OyVIBSmLUu')) failures.push('Edward interview video link is missing.');
if (!html.includes('1_jNwYnOfR1bi2eZV6n776MyAOXKpNJON')) failures.push('Deployment evidence video link is missing.');
if (!curriculum.includes('Core learning areas') || !curriculum.includes('For community partners')) failures.push('Curriculum does not match the approved community-training direction.');
if (!html.includes('href="/organizations/#inquiry"') || !curriculum.includes('href="/organizations/#inquiry"')) failures.push('Primary organization CTAs do not route to the on-site inquiry flow.');
if (!html.includes('/assets/css/option-3.css?v=20260808-1') || !html.includes('/assets/css/campaign.css?v=20260808-2') || !html.includes('/assets/js/main.js?v=20260808-1')) failures.push('Current homepage asset versions are missing.');

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
console.log(`Content checks passed: campaign positioning, authentic participant evidence, unnumbered visual structure, curriculum, organization inquiry, ${legalPages.length} policy pages, forms, CTA destinations, and internal links.`);
