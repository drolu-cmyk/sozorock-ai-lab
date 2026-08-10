#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const slugs = ['privacy','terms','cookies','acceptable-use','responsible-ai','accessibility','nondiscrimination','data-rights','security','copyright','media-consent','grievances'];

const header = '<header class="site-header"><div class="header-inner"><a class="capability-brand" href="/" aria-label="SozoRock AI Lab home"><span>SOZOROCK</span><span>AI LAB</span></a><nav class="legal-nav" aria-label="Primary navigation"><a href="/">Home</a><a href="/curriculum/">Curriculum</a><a href="/#apply">Apply</a><a href="/organizations/">For organizations</a><a href="https://www.sozorockfoundation.org/" rel="noopener">Foundation</a></nav></div></header>';
const footer = '<footer class="site-footer"><div class="footer-grid"><div class="footer-brand"><a class="capability-brand footer-capability-brand" href="/" aria-label="SozoRock AI Lab home"><span>SOZOROCK</span><span>AI LAB</span></a><p>SozoRock AI Lab is a no-cost education program of The SozoRock Foundation, Inc., a nonprofit, tax-exempt charitable organization.</p><a class="footer-foundation" href="https://www.sozorockfoundation.org/" rel="noopener">Visit the Foundation website</a></div><nav class="footer-col" aria-label="Program"><h2>Program</h2><a href="/">AI Lab</a><a href="/curriculum/">Curriculum</a><a href="/#apply">Apply</a><a href="/organizations/">For organizations</a></nav><nav class="footer-col" aria-label="Policies"><h2>Policies</h2><a href="/privacy/">Privacy notice</a><a href="/cookies/">Cookie notice</a><a href="/terms/">Terms</a><a href="/data-rights/">Data rights</a><a href="/acceptable-use/">Acceptable use</a></nav><nav class="footer-col" aria-label="Standards"><h2>Standards</h2><a href="/responsible-ai/">Responsible AI</a><a href="/accessibility/">Accessibility</a><a href="/nondiscrimination/">Nondiscrimination</a></nav><nav class="footer-col" aria-label="Help and reporting"><h2>Help &amp; reporting</h2><a href="/organizations/#inquiry">Contact the AI Lab</a><a href="/security/">Privacy or security concern</a><a href="/grievances/">Complaint or grievance</a><a href="/copyright/">Copyright</a><a href="/media-consent/">Media consent</a></nav></div><div class="footer-bottom"><p>&copy; 2026 The SozoRock Foundation, Inc. All rights reserved.</p></div></footer>';
const internalNote = '<p class="legal-note">This public policy is operational guidance, not legal advice. The Foundation may revise it after legal, security, accessibility, or program review.</p>';

for (const slug of slugs) {
  const file = path.join(root, 'site', slug, 'index.html');
  let source = fs.readFileSync(file, 'utf8');
  source = source.replace(/<header class="site-header">[\s\S]*?<\/header>/, header);
  source = source.replace(/<footer class="site-footer">[\s\S]*?<\/footer>/, footer);
  source = source.replace(internalNote, '');
  source = source.replaceAll('SozoRock AI Capability Lab', 'SozoRock AI Lab');
  source = source.replaceAll('AI Capability Lab', 'AI Lab');
  source = source.replaceAll('Security or AI incident', 'Privacy or security concern');
  source = source.replaceAll('Report an AI or security incident', 'Report a privacy or security concern');
  source = source.replaceAll('href="/assets/css/styles.css"', 'href="/assets/css/styles.css?v=20260810-1"');
  source = source.replaceAll('July 15, 2026', 'August 10, 2026');
  source = source.replaceAll('2026-07-15', '2026-08-10');
  source = source.replaceAll('August 4, 2026', 'August 10, 2026');
  source = source.replaceAll('August 6, 2026', 'August 10, 2026');
  source = source.replaceAll('2026-08-04', '2026-08-10');
  source = source.replaceAll('2026-08-06', '2026-08-10');
  source = source.replace(/<title>([^<]+) \| SozoRock AI Lab<\/title>/, '<title>$1 | SozoRock AI Lab</title>');
  source = source.replace(/SozoRock AI Lab is an independent program of The SozoRock Foundation[^<]*OpenAI[^<]*\.?/gi, 'SozoRock AI Lab is a program of The SozoRock Foundation, Inc.');
  fs.writeFileSync(file, source);
}
